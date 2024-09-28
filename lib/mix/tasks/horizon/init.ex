defmodule Mix.Tasks.Horizon.Init do
  use Mix.Task
  @shortdoc "Initializes Horizon deployment scripts in bin/"

  @moduledoc """
  Initializes Horizon deploy scripts

  ## Options

    * `-y` - Overwrite files without asking for confirmation.

  ## Configuration

  You can configure the pathnames and deployment settings in your project's `config/config.exs`.

  ## Examples

      mix horizon.init
      mix horizon.init -y
  """

  @impl true
  def run(args) do
    # Ensure the app is started
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, switches: [yes: :boolean], aliases: [y: :yes])

    overwrite = Keyword.get(opts, :yes, false)
    dbg(overwrite)

    # Fetch configuration
    config = Application.get_env(:horizon, :horizon, [])
    dbg(config)
    mix_config = Mix.Project.config()

    # Verify mix alias assets.setup.freebsd exists.
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

      exit(1)
    end

    app = Keyword.get(config, :deploy_app, Mix.Project.config()[:app])
    dbg(app)

    bin_dir = Keyword.get(config, :bin_dir, "bin")
    dbg(bin_dir)

    build_machine_user = Keyword.get(config, :build_machine_user, "$(whoami)")
    dbg(build_machine_user)

    build_machine_host = Keyword.get(config, :build_machine_host)
    dbg(build_machine_host)

    build_dir = Keyword.get(config, :build_dir, "/usr/local/opt/#{app}/build")
    dbg(build_dir)

    data_dir = Keyword.get(config, :data_dir, "/usr/local/opt/#{app}/data")
    dbg(data_dir)

    # Generate the cpproj.sh script
    # priv/templates/horizon/cpproj.sh.eex
    source_template = "cpproj.sh.eex"
    {:ok, cpproj_path} = get_template_path(source_template)
    dbg(cpproj_path)

    {:ok, template_content} = File.read(cpproj_path)

    eex_template =
      EEx.eval_string(template_content,
        assigns: %{
          app: app,
          build_machine_user: build_machine_user,
          build_machine_host: build_machine_host,
          build_dir: build_dir,
          data_dir: data_dir
        }
      )

    file = Path.join(bin_dir, "horizon_cp_proj.sh")
    File.write!(file, eex_template)
    File.chmod!(file, 0o755)

    source_template = "release.sh.eex"
    {:ok, release_path} = get_template_path(source_template)
    dbg(release_path)

    {:ok, template_content} = File.read(release_path)

    eex_template =
      EEx.eval_string(template_content,
        assigns: %{
          app: app,
          build_machine_user: build_machine_user,
          build_machine_host: build_machine_host,
          build_dir: build_dir,
          data_dir: data_dir
        }
      )

    file = Path.join(bin_dir, "release.sh")
    File.write!(file, eex_template)
    File.chmod!(file, 0o755)

    # write the full path to tailwind in tailwind.data
    # the fullpath will be in build_dir/tailwind-freebsd-#{arch}
    tailwind = Path.join([build_dir, "_build", "tailwind-#{target()}"])
    dbg(tailwind)

    # copy horizon_helpers.sh to bin/
    {:ok, script} = get_script_path("horizon_helpers.sh")
    dbg(script)

    File.cp(script, Path.join(bin_dir, "horizon_helpers.sh"))

    # target_dir = Path.join(File.cwd!(), bin_dir)
    # File.mkdir_p!(target_dir)

    # Enum.each(scripts, fn %{source: source_script, target: target_script} ->
    #   source_path = Path.expand("priv/scripts/#{source_script}", :horizon)
    #   target_path = Path.join(target_dir, target_script)

    #   if File.exists?(target_path) and not overwrite do
    #     overwrite? =
    #       Mix.shell().yes?("#{target_script} already exists in #{bin_dir}. Overwrite? [y/N]")

    #     if overwrite? do
    #       copy_script(source_path, target_path)
    #     else
    #       Mix.shell().info("Skipped #{target_script}")
    #     end
    #   else
    #     copy_script(source_path, target_path)
    #   end
    # end)
  end

  defp get_template_path(source_template) do
    case Application.app_dir(:horizon, "priv/templates/horizon/#{source_template}") do
      nil ->
        {:error, "Template not found."}

      path ->
        {:ok, path}
    end
  end

  defp get_script_path(source_script) do
    case Application.app_dir(:horizon, "bin/#{source_script}") do
      nil ->
        {:error, "Script not found."}

      path ->
        {:ok, path}
    end
  end

  # defp copy_script(source, target) do
  #   case File.cp(source, target) do
  #     :ok ->
  #       # Ensure the script is executable
  #       File.chmod(target, 0o755)
  #       Mix.shell().info("Copied #{Path.basename(target)} to #{Path.dirname(target)}")

  #     {:error, reason} ->
  #       Mix.shell().error("Failed to copy #{Path.basename(target)}: #{reason}")
  #   end
  # end

  defp target do
    arch_str = :erlang.system_info(:system_architecture)
    [arch | _] = arch_str |> List.to_string() |> String.split("-")

    case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
      {{:win32, _}, _arch, 64} -> "windows-x64.exe"
      {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) -> "macos-arm64"
      {{:unix, :darwin}, "x86_64", 64} -> "macos-x64"
      {{:unix, :freebsd}, "aarch64", 64} -> "freebsd-arm64"
      {{:unix, :freebsd}, "amd64", 64} -> "freebsd-x64"
      {{:unix, :linux}, "aarch64", 64} -> "linux-arm64"
      {{:unix, :linux}, "arm", 32} -> "linux-armv7"
      {{:unix, :linux}, "armv7" <> _, 32} -> "linux-armv7"
      {{:unix, _osname}, arch, 64} when arch in ~w(x86_64 amd64) -> "linux-x64"
      {_os, _arch, _wordsize} -> raise "tailwind is not available for architecture: #{arch_str}"
    end
  end
end
