defmodule Horizon.Ops.BSD.ConfigTest do
  use ExUnit.Case
  alias Horizon.Ops.BSD.Config

  describe "merge_defaults/1" do
    test "merges default values into the release options" do
      options = []

      expected_releases = [
        my_app: [
          {:path, "/usr/local/my_app"},
          {:bin_path, "bin"},
          {:build_path, "/usr/local/opt/my_app/build"},
          {:releases_path, ".releases"},
          {:build_host_ssh, "USER@HOSTUNKNOWN"}
        ]
      ]

      updated_releases = Config.merge_defaults(my_app: options)

      assert updated_releases == expected_releases
    end

    test "uses user provided path values" do
      options = [
        name: :my_app,
        version: "1.0.0",
        path: "/some/full/path/my_app",
        version_path: "some/full/path/1.0.0",
        bin_path: "my_bin"
      ]

      expected_releases = [
        my_app: [
          {:build_path, "/usr/local/opt/my_app/build"},
          {:releases_path, ".releases"},
          {:build_host_ssh, "USER@HOSTUNKNOWN"},
          {:name, :my_app},
          {:version, "1.0.0"},
          {:path, "/some/full/path/my_app"},
          {:version_path, "some/full/path/1.0.0"},
          {:bin_path, "my_bin"}
        ]
      ]

      updated_releases = Config.merge_defaults(my_app: options)

      assert updated_releases == expected_releases
    end
  end
end
