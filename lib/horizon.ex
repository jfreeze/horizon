defmodule Horizon do
  @moduledoc """
  Horizon is a tool for building and deploying Elixir applications.

  """

  @doc """
  Returns a tuple with the full source path and the target file name.

  ## Examples

        iex> get_src_tgt(:stage_for_build, "foo")
        {"/path_to_horizon/priv/horizon_sources/bin/stage_for_build.sh.eex", "stage_foo.sh"}

  """
  @spec get_src_tgt(atom(), String.t() | atom()) :: {String.t(), String.t()}
  def get_src_tgt(:stage_for_build, app) do
    {get_src_path("bin", "stage_for_build.sh.eex"), "stage-#{app}.sh"}
  end

  def get_src_tgt(:bsd_install, _app) do
    {get_src_path("bin", "bsd_install.sh.eex"), "bsd_install.sh"}
  end

  def get_src_tgt(:release, app) do
    {get_src_path("bin", "release.sh.eex"), "release-#{app}.sh"}
  end

  def get_src_tgt(:helpers, _app) do
    {get_src_path("bin", "horizon_helpers.sh"), "horizon_helpers.sh"}
  end

  @spec get_src_path(atom, String.t()) :: String.t() | no_return()
  def get_src_path(dir, source) do
    case Application.app_dir(:horizon, "priv/horizon_sources/#{dir}/#{source}") do
      nil ->
        raise "Source file '#{source}' not found."

      path ->
        path
    end
  end

  # @doc """
  # Returns the target platform for the current system.
  # """
  # def target do
  #   arch_str = :erlang.system_info(:system_architecture)
  #   [arch | _] = arch_str |> List.to_string() |> String.split("-")

  #   case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
  #     {{:win32, _}, _arch, 64} -> "windows-x64.exe"
  #     {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) -> "macos-arm64"
  #     {{:unix, :darwin}, "x86_64", 64} -> "macos-x64"
  #     {{:unix, :freebsd}, "aarch64", 64} -> "freebsd-arm64"
  #     {{:unix, :freebsd}, "amd64", 64} -> "freebsd-x64"
  #     {{:unix, :linux}, "aarch64", 64} -> "linux-arm64"
  #     {{:unix, :linux}, "arm", 32} -> "linux-armv7"
  #     {{:unix, :linux}, "armv7" <> _, 32} -> "linux-armv7"
  #     {{:unix, _osname}, arch, 64} when arch in ~w(x86_64 amd64) -> "linux-x64"
  #     {_os, _arch, _wordsize} -> raise "tailwind is not available for architecture: #{arch_str}"
  #   end
  # end

  @doc """
  Validate that the `assets.setup.freebsd` alias exists in the mix.exs file.

  """
  @spec warn_is_missing_freebsd_alias(keyword()) :: no_return()
  def warn_is_missing_freebsd_alias(mix_config) do
    if is_nil(mix_config[:aliases][:"assets.setup.freebsd"]) do
      Mix.shell().error("Please add the assets.setup.freebsd alias to your mix.exs file.")

      msg = ~S"""

      A common alias for setting up a FreeBSD build environment is as follows:

      "assets.setup.freebsd": [
        "tailwind.install #{@tailwindcss_freebsd_x64}",
        "esbuild.install --if-missing"
      ]

      with @tailwindcss_freebsd_x64 defined in your mix.exs file as:

      @tailwindcss_freebsd_x64 "https://people.freebsd.org/~dch/pub/tailwind/v$version/tailwindcss-$target"
      """

      Mix.shell().info(msg)
    end
  end

  @doc """
  Returns the configuration for the releases.
  If no releases are defined in the mix.exs file, a default release returned.

  """
  def get_config_releases do
    mix_config = Mix.Project.config()
    app_name = mix_config[:app]

    releases =
      case mix_config[:releases] do
        nil ->
          configure_default_paths([{app_name, [is_default?: true]}])

        releases ->
          configure_default_paths(releases)
      end

    validate_releases(releases)
    releases
  end

  @doc """
  Configure default paths for releases.

  ## Examples

          iex> configure_default_paths([my_app: []], "my_app")
          [
            my_app: [
              bin_path: "bin",
              path: "/usr/local/my_app",
              build_path: "/usr/local/opt/my_app/build",
              build_host: "HOSTUNKNOWN",
              build_user: "$(whoami)"
            ]
          ]

  """
  @spec configure_default_paths(keyword()) :: keyword()
  def configure_default_paths(releases) do
    releases
    |> maybe_set_default(:bin_path, "bin")
    |> maybe_set_default(:path, &"/usr/local/#{&1}")
    |> maybe_set_default(:build_path, &"/usr/local/opt/#{&1}/build")
    |> maybe_set_default(:build_host, "HOSTUNKNOWN")
    |> maybe_set_default(:build_user, "$(whoami)")
  end

  #
  # ## Examples
  #   iex> maybe_set_default(releases, :path, app_name, &"/usr/local/#{&1}")
  #   iex> maybe_set_default(releases, :build_path, app_name, &"/usr/local/opt/#{&1}/build")
  #
  defp maybe_set_default(releases, key, path_fn) do
    Enum.map(releases, fn {app, opts} ->
      {app, Keyword.update(opts, key, get_path(path_fn, app), & &1)}
    end)
  end

  defp get_path(path_fn, app_name) when is_function(path_fn) do
    path_fn.(app_name)
  end

  defp get_path(path_fn, _app_name) do
    path_fn
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
        Mix.shell().info("Created #{target}")

      overwrite ->
        copy_file(source, target, executable)
        Mix.shell().info("Overwrote #{target}")

      Mix.shell().yes?("#{target} already exists. Overwrite? [y/N]") ->
        copy_file(source, target, executable)
        Mix.shell().info("Overwrote #{target}")

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
        Mix.shell().info("Created #{file}")

      overwrite ->
        write_file(data, file, executable)
        Mix.shell().info("Overwrote #{file}")

      Mix.shell().yes?("#{file} already exists. Overwrite? [y/N]") ->
        write_file(data, file, executable)
        Mix.shell().info("Overwrote #{file}")

      true ->
        Mix.shell().info("Skipped #{file}")
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
    releases #=> ["phx_only -> build_user", "phx_only -> build_host"]

  """
  @spec validate_releases(keyword()) :: [String.t()]
  def validate_releases(releases) do
    results = validate_releases(releases, [])

    if Enum.any?(results) do
      Mix.shell().error("The following releases configuration are missing values:")
      Enum.each(results, &Mix.shell().error(&1))
    end
  end

  defp validate_releases(data, path) when is_list(data) do
    data
    |> Enum.flat_map(fn
      {key, value} when is_list(value) or is_map(value) ->
        validate_releases(value, path ++ [key])

      {key, nil} ->
        [Enum.join(path ++ [key], " -> ")]

      _ ->
        []
    end)
  end

  defp validate_releases(_data, _path), do: []
end
