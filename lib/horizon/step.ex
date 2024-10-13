defmodule Horizon.Step do
  @moduledoc """
  The Horizon.Step module contains steps that are used to
  perform tasks during the release process.

  - `setup/1` - Run all the needed release steps.
  - `echo/1` - Echo the release name and options to the console.
  - `merge_defaults/1` - Merges the Horizon defaults into the release options.
  - `setup_rcd/1` - Create the rc.d script for the release.

  """

  @doc """
  Run the merge and rcd release steps.
  """
  @spec setup(Mix.Release.t()) :: Mix.Release.t()
  def setup(%Mix.Release{} = release) do
    release
    |> merge_defaults()
    |> setup_rcd()
  end

  @doc """
  Echo the release name and options to the console.
  """
  @spec echo(Mix.Release.t()) :: Mix.Release.t()
  def echo(%Mix.Release{name: name} = release) do
    pr = release |> Map.delete(:applications) |> Map.delete(:boot_scripts)
    IO.puts("\u001b[32;1m == Horizon.Step.echo/1 ==\u001b[0m")
    IO.inspect(pr, label: "Truncated release for #{name}")
    release
  end

  @doc """
  Merges the Horizon defaults into the release options.

  Calling this step will override Elixir's default value for `release.path`.
  We check
  """
  @spec merge_defaults(Mix.Release.t()) :: Mix.Release.t()
  def merge_defaults(%Mix.Release{name: name} = release) do
    release = Map.update(release, :options, [], &Horizon.Config.merge_defaults(&1, name))
    release = Map.put(release, :path, Keyword.get(release.options, :path))
    File.write("release.exs", "#{inspect(release)}\n")
    release
  end

  @doc """
  Create the rc.d script for the release.
  This script is created on the build host and not part of `mix horizon.init`.

  """
  @spec setup_rcd(Mix.Release.t()) :: Mix.Release.t()
  def setup_rcd(%Mix.Release{name: name, options: options} = release) do
    file = "/usr/local/etc/rc.d/#{name}"

    # We don't overwrite the rc.d script.
    # The admin must delete it then run release.sh.
    if File.exists?(file) do
      IO.puts([
        IO.ANSI.yellow(),
        IO.ANSI.bright(),
        "  => #{file} exists",
        IO.ANSI.reset()
      ])
    else
      IO.puts([
        IO.ANSI.yellow(),
        IO.ANSI.bright(),
        "  => Creating #{file}",
        IO.ANSI.reset()
      ])

      Horizon.create_file_from_template(
        :rc_d,
        name,
        false,
        true,
        options,
        &Horizon.assigns/2,
        fn _app, _opts -> file end
      )
    end

    release
  end
end
