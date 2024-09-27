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

    # Fetch configuration
    config = Application.get_env(:horizon, :horizon, [])

    deploy_app = Keyword.get(config, :deploy_app, Mix.Project.config()[:app] |> to_string())

    bin_dir = Keyword.get(config, :bin_dir, "bin")

    scripts = [
      %{source: "deploy.sh", target: "deploy.sh"},
      %{source: "release.sh", target: "release.sh"},
      %{source: "installer.sh", target: "installer_#{deploy_app}.sh"},
      %{source: "bsd_install_script.sh", target: "install_script.sh"},
      %{source: "bsd_install_script_args.sh", target: "install_args.sh"}
    ]

    target_dir = Path.join(File.cwd!(), bin_dir)
    File.mkdir_p!(target_dir)

    Enum.each(scripts, fn %{source: source_script, target: target_script} ->
      source_path = Path.expand("priv/scripts/#{source_script}", :horizon)
      target_path = Path.join(target_dir, target_script)

      if File.exists?(target_path) and not overwrite do
        overwrite? =
          Mix.shell().yes?("#{target_script} already exists in #{bin_dir}. Overwrite? [y/N]")

        if overwrite? do
          copy_script(source_path, target_path)
        else
          Mix.shell().info("Skipped #{target_script}")
        end
      else
        copy_script(source_path, target_path)
      end
    end)
  end

  defp copy_script(source, target) do
    case File.cp(source, target) do
      :ok ->
        # Ensure the script is executable
        File.chmod(target, 0o755)
        Mix.shell().info("Copied #{Path.basename(target)} to #{Path.dirname(target)}")

      {:error, reason} ->
        Mix.shell().error("Failed to copy #{Path.basename(target)}: #{reason}")
    end
  end
end
