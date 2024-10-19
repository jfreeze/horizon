defmodule Horizon.Ops.BSD.StepTest do
  use ExUnit.Case
  alias Horizon.Ops.BSD.Step

  describe "merge_defaults/1" do
    test "merges default values into the release" do
      release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "/full/path/to/project/_build/prod/rel/my_app",
        version_path: "/full/path/to/project/_build/prod/rel/my_app/releases/1.0.0"
      }

      expected_release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "/usr/local/my_app",
        version_path: "/usr/local/my_app/releases/1.0.0",
        options: [
          {:path, "/usr/local/my_app"},
          {:bin_path, "bin"},
          {:build_path, "/usr/local/opt/my_app/build"},
          {:releases_path, ".releases"},
          {:build_host, "HOSTUNKNOWN"},
          {:build_user, "$(whoami)"}
        ]
      }

      updated_release = Step.merge_defaults(release)

      assert updated_release == expected_release
    end

    test "does not override existing values" do
      release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "_build/prod/rel/my_app",
        version_path: "/full/path/_build/prod/rel/my_app/releases/1.0.0",
        applications: [:my_custom_app]
      }

      expected_release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "/usr/local/my_app",
        version_path: "/usr/local/my_app/releases/1.0.0",
        applications: [:my_custom_app],
        boot_scripts: nil,
        erts_source: nil,
        erts_version: nil,
        config_providers: nil,
        options: [
          path: "/usr/local/my_app",
          bin_path: "bin",
          build_path: "/usr/local/opt/my_app/build",
          releases_path: ".releases",
          build_host: "HOSTUNKNOWN",
          build_user: "$(whoami)"
        ],
        overlays: nil,
        steps: nil
      }

      updated_release = Step.merge_defaults(release)
      assert updated_release == expected_release
    end

    test "user can override path" do
      release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "_build/prod/rel/my_app",
        version_path: "/full/path/_build/prod/rel/my_app/releases/1.0.0",
        applications: [:my_custom_app],
        options: [
          path: "/usr/phoenix/my_app",
          bin_path: "bin_myapp"
        ]
      }

      expected_release = %Mix.Release{
        name: :my_app,
        version: "1.0.0",
        path: "/usr/phoenix/my_app",
        version_path: "/usr/phoenix/my_app/releases/1.0.0",
        applications: [:my_custom_app],
        boot_scripts: nil,
        erts_source: nil,
        erts_version: nil,
        config_providers: nil,
        options: [
          build_path: "/usr/local/opt/my_app/build",
          releases_path: ".releases",
          build_host: "HOSTUNKNOWN",
          build_user: "$(whoami)",
          path: "/usr/phoenix/my_app",
          bin_path: "bin_myapp"
        ],
        overlays: nil,
        steps: nil
      }

      updated_release = Step.merge_defaults(release)
      assert updated_release == expected_release
    end
  end
end
