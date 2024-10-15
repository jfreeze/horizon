defmodule Horizon.Config do
  @moduledoc """
  Horizon configuration.
  """

  @doc """
  Merge default options into release.options and
  set release.path and release.version_path.

  ## Examples

      iex> releases = [my_app: [path: "/usr/apps/my_app"]]
      iex> merge_defaults(releases)
      [
        my_app: [
          bin_path: "bin",
          build_path: "/usr/local/opt/my_app/build",
          releases_path: ".releases",
          build_host: "HOSTUNKNOWN",
          build_user: "$(whoami)",
          path: "/usr/my_app"
        ]
      ]
      iex> merge_defaults([my_app: []])
      [
        my_app: [
          path: "/usr/local/my_app",
          bin_path: "bin",
          build_path: "/usr/local/opt/my_app/build",
          releases_path: ".releases",
          build_host: "HOSTUNKNOWN",
          build_user: "$(whoami)"
        ]
      ]

  """
  @spec merge_defaults(keyword()) :: keyword()
  def merge_defaults(releases) do
    Enum.map(releases, fn {app, release} ->
      {app, merge_release(release)}
    end)
  end

  @doc """
  Merge default options into release.options and
  set release.path and release.version_path.

  """
  @spec merge_release(Mix.Release.t()) :: Mix.Release.t()
  def merge_release(%Mix.Release{} = release) do
    options = Map.get(release, :options) || []
    updated_options = merge_default_options(options, release.name)
    path = Keyword.get(options, :path, default_options(release.name)[:path])

    version_path = Path.join([path, "releases", release.version])

    release
    |> Map.put(:path, path)
    |> Map.put(:version_path, version_path)
    |> Map.put(:options, updated_options)
  end

  @doc """
  Merge default options with release options.

  ## Examples

        iex> merge_defaults([], "foo")
        [
          path: "/usr/local/foo",
          bin_path: "bin",
          build_path: "/usr/local/opt/foo/build",
          releases_path: ".releases",
          build_host: "HOSTUNKNOWN",
          build_user: "$(whoami)"
        ]

  """
  @spec merge_default_options(keyword(), String.t() | atom()) :: keyword()
  def merge_default_options(opts, name) do
    Keyword.merge(default_options(name), opts)
  end

  defp default_options(name) do
    [
      path: "/usr/local/#{name}",
      bin_path: "bin",
      build_path: "/usr/local/opt/#{name}/build",
      releases_path: ".releases",
      build_host: "HOSTUNKNOWN",
      build_user: "$(whoami)"
    ]
  end
end
