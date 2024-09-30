defmodule Horizon do
  @moduledoc """
  Horizon is a tool for building and deploying Elixir applications.

  """

  @doc """
  Returns the full path to the template file.

  ## Examples

        iex> get_template_path("stage_for_build.sh.eex")
        {:ok, "/path_to_horizon/priv/templates/bin/stage_for_build.sh.eex"}
  """

  def get_file_path(:stage_for_build), do: get_template_path("bin", "stage_for_build.sh.eex")

  def get_file_path(dir, source_template) do
    case Application.app_dir(:horizon, "priv/templates/#{dir}/#{source_template}") do
      nil ->
        {:error, "Template not found."}

      path ->
        {:ok, path}
    end
  end

  defp get_script_path(source_script) do
    case Application.app_dir(:horizon, "priv/bin/#{source_script}") do
      nil ->
        {:error, "Script not found."}

      path ->
        {:ok, path}
    end
  end

  @moduledoc """
  Documentation for `Horizon`.
  """

  # @doc """
  # Returns the target platform for the current system.
  # """
  # def target do
  #   arch_str = :erlang.system_info(:system_architecture)
  #   [arch | _] = arch_str |> List.to_string() |> String.split("-")

  #   case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
  #     {{:win32, _}, _arch, 64} -> "windows-x64.exe"
  #     {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) -> "macos-arm64"
  #     {{:unix, :darwin}, "x86_64", 64} -> "macos-x64"
  #     {{:unix, :freebsd}, "aarch64", 64} -> "freebsd-arm64"
  #     {{:unix, :freebsd}, "amd64", 64} -> "freebsd-x64"
  #     {{:unix, :linux}, "aarch64", 64} -> "linux-arm64"
  #     {{:unix, :linux}, "arm", 32} -> "linux-armv7"
  #     {{:unix, :linux}, "armv7" <> _, 32} -> "linux-armv7"
  #     {{:unix, _osname}, arch, 64} when arch in ~w(x86_64 amd64) -> "linux-x64"
  #     {_os, _arch, _wordsize} -> raise "tailwind is not available for architecture: #{arch_str}"
  #   end
  # end
end
