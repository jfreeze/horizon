defmodule Horizon.Ops.Utils do
  @moduledoc """
  Horizon.Ops is a tool for building and deploying
  Elixir applications to FreeBSD hosts.

  """

  @doc """
  Copy a file from source to target, overwriting if necessary.

  ## Example

        iex> safe_copy_file(
        ...>   :horizon_helpers,
        ...>   app,
        ...>   overwrite,
        ...>   false,
        ...>   opts,
        ...>   &Path.join(&2[:bin_path], &1)
        ...> )

  """
  @spec copy_static_file(
          {String.t(), String.t()},
          boolean(),
          boolean(),
          keyword(),
          function()
        ) ::
          no_return()
  def copy_static_file({source, target}, overwrite, executable, opts, target_fn) do
    target = target_fn.(target, opts)

    # Ensure the target directory exists
    File.mkdir_p(Path.dirname(target))
    safe_copy_file(source, target, overwrite, executable)
  end

  @doc """
  Create a file from a template.

  ## Example

        iex> create_file_from_template("source", "target", true, false, %{}, &assigns/2, fn target,
        ...>                                                                                opts ->
        ...>   target
        ...> end)

  """
  @spec create_file_from_template(
          {String.t(), String.t()},
          String.t() | atom(),
          boolean(),
          boolean(),
          keyword(),
          function(),
          function()
        ) ::
          no_return()
  def create_file_from_template(
        {source, target},
        app,
        overwrite,
        executable,
        opts,
        assigns_fn,
        target_fn
      ) do
    target = target_fn.(target, opts)
    target_dir = Path.dirname(target)

    if not File.exists?(target_dir) do
      File.mkdir_p(target_dir)
    end

    {:ok, template_content} = File.read(source)
    eex_template = EEx.eval_string(template_content, assigns_fn.(app, opts))
    safe_write(eex_template, target, overwrite, executable)
  end

  @doc """
  Safely copy a file from source to target.

  ## Example

          iex> safe_copy_file("source", "target", true)
          Created target

  """
  @spec safe_copy_file(String.t(), String.t(), boolean(), boolean()) :: no_return()
  def safe_copy_file(source, target, overwrite, executable \\ false) do
    cond do
      not File.exists?(target) ->
        copy_file(source, target, executable)
        Mix.shell().info([:green, "Created   ", :reset, target])

      overwrite ->
        copy_file(source, target, executable)
        Mix.shell().info([:yellow, "Overwrote ", :reset, target])

      Mix.shell().yes?("#{target} already exists. Overwrite? [y/N]") ->
        copy_file(source, target, executable)
        Mix.shell().info([:yellow, "Overwrote ", :reset, target])

      true ->
        Mix.shell().info("Skipped #{target}")
    end
  end

  defp copy_file(source, target, executable) do
    case File.cp(source, target) do
      :ok ->
        if executable, do: File.chmod!(target, 0o755)

      {:error, reason} ->
        Mix.shell().error("Failed to copy #{target}: #{reason}")
    end
  end

  def safe_write(data, file, overwrite, executable \\ false) do
    cond do
      not File.exists?(file) ->
        write_file(data, file, executable)
        Mix.shell().info([:green, "Created   ", :reset, file])

      overwrite ->
        write_file(data, file, executable)
        Mix.shell().info([:yellow, "Overwrote ", :reset, file])

      Mix.shell().yes?("#{file} already exists. Overwrite? [y/N]") ->
        write_file(data, file, executable)
        Mix.shell().info([:yellow, "Overwrote ", :reset, file])

      true ->
        Mix.shell().info("Skipped   #{file}")
    end
  end

  defp write_file(data, file, executable) do
    case File.write(file, data) do
      :ok ->
        if executable, do: File.chmod!(file, 0o755)

      {:error, reason} ->
        Mix.shell().error("Failed to write to #{file}: #{inspect(reason)}")
    end
  end

  @doc """
  Validate the releases configuration for nil values.

  ## Examples

    iex> validate_releases([..., build_user: nil, ..])
    # => ["phx_only -> build_user", "phx_only -> build_host"]
    releases

  """
  @spec validate_releases(keyword()) :: :ok | nil
  def validate_releases(releases) do
    results = validate_releases(releases, [])

    if Enum.any?(results) do
      Mix.shell().error("Some releases have missing or nil configuration values.")

      Mix.shell().error(
        "Check `mix.exs` for missing config values or unset environment variables."
      )

      Enum.each(results, &Mix.shell().error(&1))
    end
  end

  defp validate_releases(data, path) when is_list(data) do
    data
    |> Enum.flat_map(fn
      {key, value} when is_list(value) or is_map(value) ->
        validate_releases(value, path ++ [key])

      {key, nil} ->
        [Enum.join(path ++ [key], ": :")]

      _ ->
        []
    end)
  end

  defp validate_releases(_data, _path), do: []
end
