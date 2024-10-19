defmodule Mix.Tasks.Horizon.Bsd.Init do
  @shortdoc "Creates Horizon.Ops deployment scripts for FreeBSD hosts."

  use Mix.Task

  @moduledoc """
  Creates Horizon.Ops deploy scripts in `bin/` and `rel/` directories.

  ## Usage

      mix horizon.bsd.init [-y]

  ### Options

    * `-y` - Overwrite files without asking for confirmation.

  ## Description

  Horizon.Ops.Bsd.init creates several scripts for deploying an Elixir application to a host.
  Horizon.Ops.Bsd is customized for FreeBSD hosts. Use Horizon.Oos.Linux for Linux hosts.

  ### Customization

  Horizon.Ops.Bsd.init uses the `releases` configuration in `mix.exs` to customize the deployment scripts.
  The available options are:

  - `bin_path`: default :`bin`
  - `path`: default: `/usr/local/<app_name>`
  - `build_user`: default: `whoami`
  - `build_host`: default: `HOSTUNKNOWN`
  - `deploy_user`: default: `whoami`
  - `deploy_host`: default: `HOSTUNKNOWN`
  - `release_commands`: default: `[]`
  - `releases_path`: default: `.releases`

  #### `bin_path`

  The directory where the scripts are created. If there is a `bin_path` for each release, scripts
  are copied to each bin directory.

  #### `path`

  The final destination of the release on the deploy host. This will be the same on deploy only hosts and the build host.

  #### `build_user`

  The username on the build machine. This is used to copy the release to the build machine.
  This is used by the `stage` script to copy the release to the build machine, but may be overridden
  on the commandline.

  #### `build_host`

  The hostname of the build machine. This is used to copy the release to the build machine.
  This is used by the `stage` script to copy the release to the build machine, but may be overridden
  on the commandline.

  #### `deploy_user`

  The username on the deploy machine. This is used to copy the release to the deploy machine.

  #### `deploy_host`

  The hostname of the deploy machine. This is used to copy the release to the deploy machine.

  #### `release_commands`

  A list of commands to run after the release is copied to the deploy machine.
  These commands should be `0` arity functions in Release.ex.

  #### `releases_path`

  The directory where releases are stored on the local host.
  The build script places the release tarball in this directory and the deploy
  script copies the release from this directory.

  ### Files Created

  Running `mix horizon.init` creates several files in the `bin_path` directory.
  For the project `my_app`, these files include:

  - `bsd_install.sh`
  - `bsd_install_args.sh`
  - `bsd_install_script.sh`
  - `horizon_helpers.sh`
  - `release-my_app.sh`
  - `build-my_app.sh`
  - `stage-my_app.sh`
  - `deploy-my_app.sh`
  - `deploy_script-my_app.sh`

  If you have multiple releases, a `stage`, and `build` and `deploy` script
  is created for each release.
  For example, imagine you have releases `app_web` and `app_worker`.
  Horizon.Ops.BSD.init will create

  - `bin/stage-app_web.sh`
  - `bin/stage-app_worker.sh`
  - `bin/build-0app_web.sh`
  - `bin/build-0app_worker.sh`
  - `bin/deploy-app_web.sh`
  - `bin/deploy-app_worker.sh`

  An rc.d script is created in `rel/overlays/rc_d/` for each release.

  """
  alias Horizon.Ops.Target

  @targets [
    # Install scripts
    %Target{executable?: true, type: :template, key: :bsd_install},
    %Target{executable?: false, type: :static, key: :bsd_install_args},
    %Target{executable?: false, type: :static, key: :bsd_install_script},
    # Subroutines
    %Target{executable?: false, type: :static, key: :horizon_helpers},
    # Release scripts
    %Target{executable?: true, type: :template, key: :stage},
    %Target{executable?: true, type: :template, key: :build},
    %Target{executable?: true, type: :template, key: :build_script},
    %Target{executable?: true, type: :template, key: :deploy},
    %Target{executable?: false, type: :template, key: :deploy_script}
    # RC scripts
    # {:executable, :template, :rc_d}
  ]

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [yes: :boolean], aliases: [y: :yes])
    overwrite = Keyword.get(opts, :yes, false)

    Horizon.Ops.BSD.Utils.warn_is_missing_freebsd_alias(Mix.Project.config())
    releases = Horizon.Ops.BSD.Utils.get_config_releases()

    static_targets = Enum.filter(@targets, &Target.is_static?/1)

    # Only copy static files once per bin_path
    {_, unique_releases} =
      Enum.reduce(releases, {MapSet.new(), []}, fn {_app, opts} = release, {bin_paths, acc} ->
        bin_path = opts[:bin_path]

        if MapSet.member?(bin_paths, bin_path) do
          {bin_paths, acc}
        else
          {MapSet.put(bin_paths, bin_path), [release | acc]}
        end
      end)

    for {app, opts} = _release <- unique_releases do
      for %{executable?: executable, key: key} <- static_targets do
        Horizon.Ops.Utils.copy_static_file(
          Horizon.Ops.BSD.Utils.get_src_tgt(key, app),
          overwrite,
          executable,
          opts,
          &Path.join(&2[:bin_path], &1)
        )
      end
    end

    bin_template_targets = Enum.filter(@targets, &Target.is_template?/1)

    for {app, opts} = _release <- releases do
      for %{executable?: executable, key: key} <- bin_template_targets do
        Horizon.Ops.Utils.create_file_from_template(
          Horizon.Ops.BSD.Utils.get_src_tgt(key, app),
          app,
          overwrite,
          executable,
          opts,
          &Horizon.Ops.BSD.Utils.assigns/2,
          &Path.join(&2[:bin_path], &1)
        )
      end
    end
  end
end
