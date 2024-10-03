defmodule Horizon.Step do
  @moduledoc """
  The Horizon.Step module contains functions that are used to
  perform specific tasks during the release process.
  """

  @doc """
  Echo the release name and options to the console.
  """
  @spec echo(Mix.Release.t()) :: Mix.Release.t()
  def echo(%Mix.Release{name: name, options: options} = release) do
    IO.inspect(name: name, options: options)
    release
  end

  @doc """
  Merges the Horizon defaults into the release options.
  """
  @spec merge_defaults(Mix.Release.t()) :: Mix.Release.t()
  def merge_defaults(%Mix.Release{name: name} = release) do
    Map.update(release, :options, [], &Horizon.Config.merge_defaults(&1, name))
  end

  @doc """
  Create the rc.d script for the release.
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