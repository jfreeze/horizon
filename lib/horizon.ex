defmodule Horizon do
  @moduledoc """
  Horizon is a tool for building and deploying
  Elixir applications to FreeBSD hosts.

  """

  @doc """
  Copy a file from source to target, overwriting if necessary.

  ## Example

        iex> safe_copy_file(:horizon_helpers, app, overwrite, false, opts, &Path.join(&2[:bin_path], &1))

  """
  @spec copy_static_file(
          Horizon.Target.key(),
          String.t() | atom(),
          boolean(),
          boolean(),
          keyword(),
          function()
        ) ::
          no_return()
  def copy_static_file(template, app, overwrite, executable, opts, target_fn) do
    {source, target} = Horizon.get_src_tgt(template, app)

    target = target_fn.(target, opts)

    # Ensure the target directory exists
    File.mkdir_p(Path.dirname(target))
    Horizon.safe_copy_file(source, target, overwrite, executable)
  end

  @doc """
  Create a file from a template.

  ## Example

        iex> create_file_from_template("source", "target", true, false, %{}, &assigns/2, fn target, opts -> target end)

  """
  @spec create_file_from_template(
          Horizon.Target.key(),
          String.t() | atom(),
          boolean(),
          boolean(),
          keyword(),
          function(),
          function()
        ) ::
          no_return()
  def create_file_from_template(template, app, overwrite, executable, opts, assigns_fn, target_fn) do
    {source, target} = Horizon.get_src_tgt(template, app)

    target = target_fn.(target, opts)
    target_dir = Path.dirname(target)

    if not File.exists?(target_dir) do
      File.mkdir_p(target_dir)
    end

    {:ok, template_content} = File.read(source)
    eex_template = EEx.eval_string(template_content, assigns_fn.(app, opts))
    Horizon.safe_write(eex_template, target, overwrite, executable)
  end

  @doc """
  Assigns the application and options to a keyword list.

  """
  @spec assigns(atom(), keyword()) :: keyword()
  def assigns(app, opts) do
    [
      assigns: [
        app: app,
        app_path: opts[:path],
        bin_path: opts[:bin_path],
        build_path: opts[:build_path],
        build_host: opts[:build_host],
        build_user: opts[:build_user] || "$(whoami)",
        deploy_host: opts[:deploy_host],
        deploy_user: opts[:deploy_user] || "$(whoami)",
        release_commands: opts[:release_commands] || [],
        releases_path: opts[:releases_path],
        is_default?: opts[:is_default?] || false
      ]
    ]
  end

  @static_files [
    :bsd_install,
    :bsd_install_args,
    :bsd_install_script,
    :horizon_helpers
  ]

  @doc """
  Returns a tuple with the full source path and the target file name.
  Files are referenced with an atom.

  Note that files in the `scripts` folder are expected to keep the same
  name from source to target. These static scripts will only be copied
  to the a `bin/` folder one time.

  ## Examples

        iex> get_src_tgt(:stage, "foo")
        {"/path_to_horizon/priv/templates/bin/stage.sh.eex", "stage-foo.sh"}

  """
  @spec get_src_tgt(atom(), String.t() | atom()) :: {String.t(), String.t()}
  def get_src_tgt(key, _app) when key in @static_files do
    {get_src_path("scripts", "#{key}.sh"), "#{key}.sh"}
  end

  def get_src_tgt(:stage, app) do
    {get_src_path("templates/bin", "stage.sh.eex"), "stage-#{app}.sh"}
  end

  def get_src_tgt(:build, app) do
    {get_src_path("templates/bin", "build.sh.eex"), "build-#{app}.sh"}
  end

  def get_src_tgt(:build_script, app) do
    {get_src_path("templates/bin", "build_script.sh.eex"), "build_script-#{app}.sh"}
  end

  def get_src_tgt(:deploy, app) do
    {get_src_path("templates/bin", "deploy.sh.eex"), "deploy-#{app}.sh"}
  end

  def get_src_tgt(:deploy_script, app) do
    {get_src_path("templates/bin", "deploy_script.sh.eex"), "deploy_script-#{app}.sh"}
  end

  def get_src_tgt(:release_on_build, app) do
    {get_src_path("templates/bin", "release_on_build.sh.eex"), "release_on_build-#{app}.sh"}
  end

  def get_src_tgt(:rc_d, app) do
    {get_src_path("templates/rc_d", "rc_d.eex"), "#{app}"}
  end

  @spec get_src_path(String.t(), String.t()) :: String.t() | no_return()
  def get_src_path(dir, source) do
    Application.app_dir(:horizon, "priv/#{dir}/#{source}")
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
  Returns the options, with defaults inserted, for each release.
  If no releases are defined in the mix.exs file, a default release returned.

  This is the configured options for releases that you set for
  each release in `mix.exs` and can be inspected with `Mix.Project.config()[:releases]`.
  Not to be confused with the `%Mix.Release{}` struct that is passed to each `Step`.
  The options here are stored in the `Mix.Release.options` field.

  """
  def get_config_releases do
    mix_config = Mix.Project.config()
    app_name = mix_config[:app]

    releases =
      case mix_config[:releases] do
        nil ->
          Horizon.Config.merge_defaults([{app_name, [is_default?: true]}])

        releases ->
          Horizon.Config.merge_defaults(releases)
      end

    validate_releases(releases)
    releases
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
