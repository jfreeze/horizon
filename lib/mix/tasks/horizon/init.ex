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
    {opts, _, _} = OptionParser.parse(args, switches: [yes: :boolean], aliases: [y: :yes])
    overwrite = Keyword.get(opts, :yes, false)

    Horizon.warn_is_missing_freebsd_alias(Mix.Project.config())
    releases = Horizon.get_config_releases()

    # Static files and their executable status
    static_targets = [
      {:helpers, false},
      {:bsd_install, true}
    ]

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
      for {template, executable} <- static_targets do
        copy_static_file(
          template,
          app,
          overwrite,
          executable,
          opts,
          &Path.join(&2[:bin_path], &1)
        )
      end
    end

    bin_targets = [
      {:stage_for_build, true},
      {:release, true}
    ]

    for {app, opts} = _release <- releases do
      for {template, executable} <- bin_targets do
        create_file_from_template(
          template,
          app,
          overwrite,
          executable,
          opts,
          &Path.join(&2[:bin_path], &1)
        )
      end
    end

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

  @doc """
  Copy a file from source to target, overwriting if necessary.

  ## Example

        iex> safe_copy_file(:helpers, app, overwrite, false, opts, &Path.join(&2[:bin_path], &1))

  """
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

        iex> create_file_from_template("source", "target", true, false, %{}, fn target, opts -> target end)

  """
  @spec create_file_from_template(String.t(), String.t(), boolean(), boolean(), map(), function()) ::
          no_return()
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
        bin_path: opts[:bin_path],
        build_path: opts[:build_path],
        build_host: opts[:build_host],
        build_user: opts[:build_user] || "$(whoami)",
        is_default?: opts[:is_default?] || false
        # path: optsdata_dir
      ]
    ]
  end
end
