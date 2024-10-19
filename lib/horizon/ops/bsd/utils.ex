defmodule Horizon.Ops.BSD.Utils do
  @moduledoc """
  Horizon.Ops is a tool for building and deploying
  Elixir applications to FreeBSD hosts.

  """

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

  def get_src_tgt(:rc_d, app) do
    {get_src_path("templates/rc_d", "rc_d.eex"), "#{app}"}
  end

  @spec get_src_path(String.t(), String.t()) :: String.t() | no_return()
  def get_src_path(dir, source) do
    Application.app_dir(:horizon_ops, "priv/#{dir}/#{source}")
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
          Horizon.Ops.BSD.Config.merge_defaults([{app_name, [is_default?: true]}])

        releases ->
          Horizon.Ops.BSD.Config.merge_defaults(releases)
      end

    Horizon.Ops.Utils.validate_releases(releases)
    releases
  end

end
