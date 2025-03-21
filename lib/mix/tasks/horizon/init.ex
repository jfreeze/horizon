defmodule Mix.Tasks.Horizon.Init do
  @shortdoc "Creates Horizon deployment scripts for FreeBSD hosts."

  use Mix.Task

  @moduledoc """
  Creates Horizon deploy scripts in `bin/` and `rel/` directories.

  ## Usage

      mix horizon.init [-y]

  ### Options

    * `-y` - Overwrite files without asking for confirmation.

  ## Description

  Horizon.Init creates scripts for deploying an Elixir application to a host.
  See [`Horizon.Ops.Init`](Mix.Tasks.Horizon.Ops.Init.html) for the creation for additional helper applications.

  Scripts are created in the `bin/` directory of the project by default,
  but each release defined in `mix.exs` may override the default path
  by setting the `bin_path` option.

  The run control script for each release is created in `rel/overlays/rc_d/` when `mix release` is run.

  ### Customization

  Horizon.Init uses the `releases` configuration in `mix.exs` to customize the deployment scripts.
  The available options are:

  - `bin_path`: `[bin/]`
    - This is the directory where the scripts are created. If there is a `bin_path` for each release, scripts
      associated with each release are copied to their respective bin directory.
  - `path`: `[/usr/local/<release_name>]`
    - This is the final destination of the release on the deploy host. This will be the same on deploy only hosts and the build host.
  - `build_host_ssh`: `[nil]`
    - If not provided, `stage` script will use env var `BUILD_HOST_SSH`. Required for the `stage` script to copy the release to the build machine and for the `build` script.
    - Example: `[user@]host`
  - `deploy_hosts_ssh`: `[[]]`
    - If not provided, ssh hosts may be passed to the `deploy` script with the `-h` option.
    - Example: `user@host1,user@host2`
  - `release_commands`: `[[]]`
    - A list of commands to run after the release is copied to the deploy machine.
    - These are typically zero arity commands defined in `release.ex`. For example, `["migrate"]`.
  - `releases_path`: `[.releases]`
    - The directory where releases are stored on the local host. The build script places the release tarball in this directory and the deploy
  script copies the release from this directory.
  - `env_path`: `[rel/overlays/.env]`
    - The path to the environment file that is sourced during the build process. This is particularly important when using `Application.compile_env` as the environment variables are required for compilation.


  ### Files Created

  Running `mix horizon.init` creates several files in the `bin_path` directory.
  For the project `my_app`, these files include:

  - `bin/horizon_helpers.sh`
  - `bin/stage-my_app.sh`
  - `bin/build-my_app.sh`
  - `bin/build_script-my_app.sh`
  - `bin/deploy-my_app.sh`
  - `bin/deploy_script-my_app.sh`

  If you have multiple releases, a `stage`, `build` and `deploy` script
  is created for each release.
  For example, imagine you have releases `app_web` and `app_worker`.
  Horizon.Ops.Init will create

  - `bin/horizon_helpers.sh`
  - `bin/stage-app_web.sh`
  - `bin/build-app_web.sh`
  - `bin/build_script-app_web.sh`
  - `bin/deploy-app_web.sh`
  - `bin/deploy_script-app_web.sh`
  - `bin/stage-app_worker.sh`
  - `bin/build-app_worker.sh`
  - `bin/build_script-app_worker.sh`
  - `bin/deploy-app_worker.sh`
  - `bin/deploy_script-app_worker.sh`

  """
  alias Horizon.Ops.Target

  @targets [
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

  @impl Mix.Task
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
