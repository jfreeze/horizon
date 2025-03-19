defmodule Mix.Tasks.Horizon.Git do
  @moduledoc """
  Mix tasks for git ref hash.
  """

  defmodule Gen.GitRef do
    use Mix.Task

    @default_file_path ".horizon/git_ref"
    @shortdoc "Display git ref hash from .horizon/git_ref"
    @moduledoc """
    Generates the current git ref hash and writes it to a file.

    This task creates a .horizon/git_ref file containing the current git ref hash.

    ## Options

      * `-h`, `--help` - Displays usage information
      * `-f`, `--file-path` - Override the default file path (.horizon/git_ref)

    ## Examples

        $ mix horizon.git.gen.git_ref
        $ mix horizon.git.gen.git_ref --help
        $ mix horizon.git.gen.git_ref --file-path=custom/path/git_ref

    """

    def run(args) do
      {opts, _remaining_args, _invalid} =
        OptionParser.parse(args,
          switches: [help: :boolean, file_path: :string],
          aliases: [h: :help, f: :file_path]
        )

      if opts[:help] do
        display_help()
      else
        generate_git_ref(opts[:file_path] || @default_file_path)
      end
    end

    defp display_help do
      Mix.shell().info("""
      Usage: mix horizon.git.gen.git_ref [options]

      Options:
        -h, --help                 Display this help message
        -f, --file-path=PATH       Override the default file path (.horizon/git_ref)
      """)
    end

    defp generate_git_ref(file_path) do
      Mix.shell().info("Generating git ref hash...")

      # Get the git ref hash
      {git_ref, 0} = System.cmd("git", ["rev-parse", "HEAD"])
      git_ref = String.trim(git_ref)

      # Truncate to first 10 characters
      short_ref = String.slice(git_ref, 0, 10)

      # Ensure directory exists
      file_path |> Path.dirname() |> File.mkdir_p!()

      # Write the git ref to the file
      File.write!(file_path, short_ref)

      Mix.shell().info("Generated git ref file at #{file_path} with ref hash: #{short_ref}")
    end
  end
end
