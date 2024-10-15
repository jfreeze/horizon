defmodule Horizon.ConfigTest do
  use ExUnit.Case
  alias Horizon.Config

  describe "merge_defaults/1" do
    test "merges default values into the release" do
      release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "/some/full/path/my_app",
        version_path: "some/full/path/1.0.0",
        options: [
          bin_path: "my_bin"
        ]
      }

      expected_releases = [
        my_app: %Mix.Release{
          name: :my_app,
          version: "1.0.0",
          path: "/usr/local/my_app",
          version_path: "/usr/local/my_app/releases/1.0.0",
          applications: nil,
          boot_scripts: nil,
          erts_source: nil,
          erts_version: nil,
          config_providers: nil,
          options: [
            path: "/usr/local/my_app",
            build_path: "/usr/local/opt/my_app/build",
            releases_path: ".releases",
            build_host: "HOSTUNKNOWN",
            build_user: "$(whoami)",
            bin_path: "my_bin"
          ],
          overlays: nil,
          steps: nil
        }
      ]

      updated_releases = Config.merge_defaults(my_app: release)

      assert updated_releases == expected_releases
    end

    test "uses user provided path values" do
      release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "_build/prod/rel/my_app",
        applications: [:my_custom_app],
        options: [
          path: "/my/deploys/my_app"
        ]
      }

      expected_releases = [
        my_app: %Mix.Release{
          name: :my_app,
          version: "1.0.0",
          path: "/my/deploys/my_app",
          version_path: "/my/deploys/my_app/releases/1.0.0",
          applications: [:my_custom_app],
          boot_scripts: nil,
          erts_source: nil,
          erts_version: nil,
          config_providers: nil,
          options: [
            bin_path: "bin",
            build_path: "/usr/local/opt/my_app/build",
            releases_path: ".releases",
            build_host: "HOSTUNKNOWN",
            build_user: "$(whoami)",
            path: "/my/deploys/my_app"
          ],
          overlays: nil,
          steps: nil
        }
      ]

      updated_release = Horizon.Config.merge_defaults(my_app: release)

      assert updated_release == expected_releases
    end
  end
end
