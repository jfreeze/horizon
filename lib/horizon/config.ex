defmodule Horizon.Config do
  @moduledoc """
  Horizon configuration.
  """

  @doc """
  Merge default options with release options.

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
    Enum.map(releases, fn {app, opts} ->
      {app, merge_defaults(opts, app)}
    end)
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
  @spec merge_defaults(keyword(), String.t() | atom()) :: keyword()
  def merge_defaults(opts, name) do
    defaults = [
      path: "/usr/local/#{name}",
      bin_path: "bin",
      build_path: "/usr/local/opt/#{name}/build",
      releases_path: ".releases",
      build_host: "HOSTUNKNOWN",
      build_user: "$(whoami)"
    ]

    Keyword.merge(defaults, opts)
  end
end
