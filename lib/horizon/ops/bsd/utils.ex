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
    dbg(opts)

    [
      assigns: [
        app: app,
        app_path: opts[:path],
        bin_path: opts[:bin_path],
        build_path: opts[:build_path],
        build_host_ssh: opts[:build_host_ssh],
        deploy_host_ssh: opts[:deploy_host_ssh],
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
    :horizon_helpers,
    :add_certbot_crontab,
    :backup_databases,
    :backup_databases_over_ssh,
    :restore_database,
    :update_database_owner,
    :turn_on_postgres_access,
    :turn_off_postgres_access,
    :turn_on_user_access,
    :turn_off_user_access,
    :freebsd_setup,
    :zfs_snapshot
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
    Application.app_dir(:horizon, "priv/#{dir}/#{source}")
  end

  @doc """
  Validate that the `assets.setup.freebsd` alias exists in the mix.exs file.

  """
  @spec warn_is_missing_freebsd_alias(keyword()) :: no_return()
  def warn_is_missing_freebsd_alias(mix_config) do
    if is_nil(mix_config[:aliases][:"assets.setup.freebsd"]) do
      Mix.shell().error("Please add the assets.setup.freebsd alias to your mix.exs file.")

      msg = ~s"""

      Horizon needs `#{IO.ANSI.yellow()}assets.setup.freebsd#{IO.ANSI.reset()}` if using tailwind.
      Update `mix.exs` with the new alias:

      # mix.exs
      #{IO.ANSI.green()}@tailwindcss_freebsd_x64 "https://people.freebsd.org/~dch/pub/tailwind/v$version/tailwindcss-$target"#{IO.ANSI.reset()}

      #{IO.ANSI.yellow()}defp aliases do
        ...
        "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      #{IO.ANSI.green()}  "assets.setup.freebsd": [
          "tailwind.install \#{@tailwindcss_freebsd_x64}",
          "esbuild.install --if-missing"
        ],#{IO.ANSI.yellow()}
        "assets.build": ["tailwind my_app1", "esbuild my_app1"],
        ...
      end}
      #{IO.ANSI.reset()}
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
