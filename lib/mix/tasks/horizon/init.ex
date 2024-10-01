defmodule Mix.Tasks.Horizon.Init do
  @shortdoc "Creates Horizon deployment scripts"

  use Mix.Task

  @moduledoc """
  Creates Horizon deploy scripts in `bin/` and `rel/` directories.

  ## Examples

      mix horizon.init
      mix horizon.init -y

  ### Options

    * `-y` - Overwrite files without asking for confirmation.

  ## Description

  Horizon.init creates several scripts for deploying an Elixir application to a host.
  Horizon is customized for FreeBSD hsts, but should be able to accomodate Linux hosts.

  ### Files Created

  A `stage` script is created in `bin/` for each release.
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

  @impl true
  def run(args) do
    # Application.ensure_all_started(:horizon)

    {opts, _, _} = OptionParser.parse(args, switches: [yes: :boolean], aliases: [y: :yes])
    overwrite = Keyword.get(opts, :yes, false)

    mix_config = Mix.Project.config()
    dbg(mix_config)

    Horizon.warn_is_missing_freebsd_alias(mix_config)

    releases = Horizon.get_config_releases()
    dbg(releases)

    for {app, opts} = release <- releases do
      dbg(app)
      dbg(opts)

      create_file_from_template(:stage_for_build, app, overwrite, true, opts, fn tgt, opts ->
        Path.join(opts[:bin_path], tgt)
      end)

      ## create release
    end

    # build_dir = Keyword.get(config, :build_dir, "/usr/local/opt/#{app}/build")
    # dbg(build_dir)

    # data_dir = Keyword.get(config, :data_dir, "/usr/local/opt/#{app}/data")
    # dbg(data_dir)

    # Generate the cpproj.sh script
    # priv/templates/horizon/cpproj.sh.eex

    # write the full path to tailwind in tailwind.data
    # the fullpath will be in build_dir/tailwind-freebsd-#{arch}
    # tailwind = Path.join([build_dir, "_build", "tailwind-#{Horizon.target()}"])
    # dbg(tailwind)

    # target_dir = Path.join(File.cwd!(), bin_dir)
    # File.mkdir_p!(target_dir)

    # Enum.each(scripts, fn %{source: source_script, target: target_script} ->
    #   source_path = Path.expand("priv/scripts/#{source_script}", :horizon)
    #   target_path = Path.join(target_dir, target_script)
  end

  def create_file_from_template(template, app, overwrite, executable, opts, target_fn) do
    {source, target} = Horizon.get_src_tgt(template, app)
    target = target_fn.(target, opts)

    {:ok, template_content} = File.read(source)
    eex_template = EEx.eval_string(template_content, assigns(app, opts))
    Horizon.safe_write(eex_template, target, overwrite, executable)
  end

  def assigns(app, opts) do
    [
      assigns: [
        app: app,
        path: opts[:path],
        build_path: opts[:build_path],
        build_host: opts[:build_host],
        build_user: opts[:build_user] || "$(whoami)"
        # path: optsdata_dir\
      ]
    ]
  end

  def write_some_file do
    # {:ok, release_path} = Horizon.get_src_path(:release)
    # dbg(release_path)

    # {:ok, template_content} = File.read(release_path)

    # eex_template =
    #   EEx.eval_string(template_content,
    #     assigns: %{
    #       app: app,
    #       build_user: build_user,
    #       build_host: build_host,
    #       build_dir: build_dir,
    #       data_dir: data_dir
    #     }
    #   )

    # file = Path.join(bin_dir, "release.sh")
    # File.write!(file, eex_template)
    # File.chmod!(file, 0o755)
  end

  # def copy_file do
  # copy horizon_helpers.sh to bin/
  # {:ok, script} = Horizon.get_src_path(:helpers)
  # target = Path.join(bin_dir, "horizon_helpers.sh")

  # IO.puts("\u001b[32;1m  ===> ----------------\u001b[0m")
  # dbg(script)
  # dbg(target)
  # result = File.cp(script, target)
  # dbg(result)
  # end
end
