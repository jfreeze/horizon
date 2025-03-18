defmodule Horizon.Ops.BSD.Step do
  @moduledoc """
  The Horizon.Ops.BSD.Step module contains steps that are used to
  perform tasks during the release process.

  - `setup/1` - Run all the needed release steps.
  - `echo/1` - Echo the release name and options to the console.
  - `merge_defaults/1` - Merges the Horizon.Ops defaults into the release options.
  - `setup_rcd/1` - Create the rc.d script for the release.
  - `setup_env/2` - Configure the environment file path for the release.

  """

  @doc """
  Run the merge, env, and rcd release steps.
  """
  @spec setup(Mix.Release.t()) :: Mix.Release.t()
  def setup(%Mix.Release{} = release) do
    release =
      release
      |> merge_defaults()
      |> setup_env()
      |> setup_rcd()

    release
  end

  @doc """
  Echo the release name and options to the console.
  """
  @spec echo(Mix.Release.t()) :: Mix.Release.t()
  def echo(%Mix.Release{name: name} = release) do
    pr = release |> Map.delete(:applications) |> Map.delete(:boot_scripts)
    IO.puts("\u001b[32;1m == Horizon.Ops.BSD.Step.echo/1 ==\u001b[0m")
    IO.inspect(pr, label: "Truncated release for #{name}")
    release
  end

  @doc """
  Merges the Horizon.Ops.BSD defaults into the release options.

  Calling this step will override Elixir's default value for
  `release.path` and `release.version_path`.

  """
  @spec merge_defaults(Mix.Release.t()) :: Mix.Release.t()
  def merge_defaults(%Mix.Release{} = release) do
    Horizon.Ops.BSD.Config.merge_release(release)
  end

  @doc """
  Create the rc.d script for the release.
  This script is created `overlays/rc_d` and copied to `/usr/local/etc/rc.d/<app>`
  during deploy.

  """
  @spec setup_rcd(Mix.Release.t()) :: Mix.Release.t()
  def setup_rcd(%Mix.Release{name: name, options: options} = release) do
    overwrite = Keyword.get(options, :overwrite, false)

    IO.puts("#{IO.ANSI.yellow()}[INFO] Creating rc.d script for #{name}#{IO.ANSI.reset()}")

    rel_template_path = get_rel_template_path(release)
    dir = Path.join(rel_template_path, "rc_d")
    File.mkdir_p(dir)
    file = Path.join(dir, "#{name}")

    Horizon.Ops.Utils.create_file_from_template(
      Horizon.Ops.BSD.Utils.get_src_tgt(:rc_d, name),
      name,
      overwrite,
      true,
      options,
      &Horizon.Ops.BSD.Utils.assigns/2,
      fn _app, _opts -> file end
    )

    release
  end

  defp get_rel_template_path(release) do
    release.options
    |> Keyword.get(:rel_templates_path, "rel/overlays")
    |> get_path()
  end

  @doc """
  Configure the environment file path for the release.

  This function sets the environment file path in the release options.
  The path is used in the build script to source environment variables
  needed during compilation, especially when using Application.compile_env.

  ## Parameters

    * `release` - The release configuration
    * `env_path` - The path to the environment file (default: "rel/overlays/.env")

  ## Examples

      steps: [
        &Horizon.Ops.BSD.Step.setup/1,
        &(Horizon.Ops.BSD.Step.setup_env(&1, "path/to/custom/env")),
        :assemble,
        :tar
      ]

    # or with the default path
      steps: [
        &Horizon.Ops.BSD.Step.setup/1,
        :assemble,
        :tar
      ]

  """
  @spec setup_env(Mix.Release.t(), String.t()) :: Mix.Release.t()
  def setup_env(%Mix.Release{options: options} = release, env_path \\ "rel/overlays/.env") do
    IO.puts(
      "#{IO.ANSI.yellow()}[INFO] Setting environment file path to #{env_path}#{IO.ANSI.reset()}"
    )

    # Store the env_path in the release options
    updated_options = Keyword.put(options, :env_path, env_path)
    %{release | options: updated_options}
  end

  defp get_path([rel_template_path | _]), do: rel_template_path
  defp get_path(rel_template_path), do: rel_template_path
end
