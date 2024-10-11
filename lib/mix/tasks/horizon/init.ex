defmodule Mix.Tasks.Horizon.Init do
  @shortdoc "Creates Horizon deployment scripts"

  use Mix.Task

  @moduledoc """
  Creates Horizon deploy scripts in `bin/` and `rel/` directories.

  ## Usage

      mix horizon.init [-y]

  ### Options

    * `-y` - Overwrite files without asking for confirmation.

  ## Description

  Horizon.init creates several scripts for deploying an Elixir application to a host.
  Horizon is customized for FreeBSD hosts, but several scripts are platform independent,
  meaning they can be used on a Linux host.

  ### Customization

  Horizon.init uses the `releases` configuration in `mix.exs` to customize the deployment scripts.
  The available options are:

  - `bin_path`: default :`bin`
  - `path`: default: `/usr/local/<app_name>`
  - `build_user`: default: `whoami`
  - `build_host`: default: `HOSTUNKNOWN`

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

  #### `stage-my_app.sh`

  Copies the project to the build machine.
  This script uses `build_path` for the project and `path` for the target of `mix release`.
  A stage script is created for each release.

  #### `bsd_install_args.sh`

  If you have multiple releases, a `stage` script is created for each release.
  For example, imagine you have releases `app_web` and `app_worker`.
  Horizon.init will create

  - `bin/stage_app_web.sh`
  - `bin/stage_app_worker.sh`

  A rc.d script is created in `??/` for each release.
  A `release` script is created in `bin/` for each release.


  Release options used by Horizon.MixProject

  - `path` - The path to the release directory on the build host. This same directory will be used on the deploy host.
  - `build_path` - The path to the project source code on the build host.
  - `build_host` - The hostname of the build machine.
  - `build_user` - The username on the build machine.

  If `releases` are not specified in `mix.exs`, the default release
  parameters using FreeBSD conventional paths are used.

  ### Files created
  - `bin/stage_my_app.sh` - copies project to build machine
  - `bin/horizon_helpers.sh` - functions for Horizon scripts
  - rc.d???
  - release...

  """
  alias Horizon.Target

  @targets [
    # Install scripts
    %Target{executable?: true, type: :template, key: :bsd_install},
    %Target{executable?: false, type: :static, key: :bsd_install_args},
    %Target{executable?: false, type: :static, key: :bsd_install_script},
    # Subroutines
    %Target{executable?: false, type: :static, key: :helpers},
    # Release scripts
    %Target{executable?: true, type: :template, key: :stage_for_build},
    %Target{executable?: true, type: :template, key: :build},
    %Target{executable?: false, type: :template, key: :build_script},
    %Target{executable?: true, type: :template, key: :release_on_build}
    # RC scripts
    # {:executable, :template, :rc_d}
  ]

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [yes: :boolean], aliases: [y: :yes])
    overwrite = Keyword.get(opts, :yes, false)

    Horizon.warn_is_missing_freebsd_alias(Mix.Project.config())
    releases = Horizon.get_config_releases()

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
        Horizon.copy_static_file(
          key,
          app,
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
        Horizon.create_file_from_template(
          key,
          app,
          overwrite,
          executable,
          opts,
          &Horizon.assigns/2,
          &Path.join(&2[:bin_path], &1)
        )
      end
    end
  end
end
