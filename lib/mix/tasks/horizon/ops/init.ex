defmodule Mix.Tasks.Horizon.Ops.Init do
  @shortdoc "Creates Horizon.Ops helpers scripts for FreeBSD hosts."

  use Mix.Task

  @moduledoc """
  Creates Horizon.Ops helper scripts in `ops/bin/ directory.

  ## Usage

      mix horizon.ops.init [-y] [path]

  ### Options

    * `-y` - Overwrite files without asking for confirmation.
    * `path` - The path to the directory where the scripts are created. Default is `ops/bin`.

  ## Description

  Horizon.Ops.Init creates several scripts for managing deployments of hosts and data.

  Running `mix horizon.ops.init` creates several files in the `ops/bin/` directory.
  These files include:

  - `bsd_install.sh`
  - `bsd_install_args.sh`
  - `bsd_install_script.sh`
  - `horizon_helpers.sh`
  - `add_certbot_crontab.sh`
  - `backup_databases.sh`
  - `backup_databases_over_ssh.sh`
  - `freebsd_setup.sh`
  - `_zfs_snapshot.sh`


  """
  alias Horizon.Ops.Target

  @targets [
    # Helper scripts
    %Target{executable?: true, type: :static, key: :bsd_install},
    %Target{executable?: true, type: :static, key: :bsd_install_args},
    %Target{executable?: false, type: :static, key: :bsd_install_script},
    %Target{executable?: true, type: :static, key: :add_certbot_crontab},
    %Target{executable?: true, type: :static, key: :backup_databases},
    %Target{executable?: true, type: :static, key: :backup_databases_over_ssh},
    %Target{executable?: true, type: :static, key: :freebsd_setup},
    # restore
    %Target{executable?: false, type: :static, key: :zfs_snapshot},
    # Subroutines
    %Target{executable?: false, type: :static, key: :horizon_helpers}
  ]

  @impl Mix.Task
  def run(args) do
    {opts, path, _} = OptionParser.parse(args, switches: [yes: :boolean], aliases: [y: :yes])
    overwrite = Keyword.get(opts, :yes, false)
    path = Enum.at(path, 0, "ops/bin")

    static_targets = Enum.filter(@targets, &Target.is_static?/1)

    for %{executable?: executable, key: key} <- static_targets do
      Horizon.Ops.Utils.copy_static_file(
        Horizon.Ops.BSD.Utils.get_src_tgt(key, nil),
        overwrite,
        executable,
        path,
        &Path.join(&2, &1)
      )
    end
  end
end
