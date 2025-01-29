defmodule Horizon.ProjectTest do
  use ExUnit.Case
  doctest Horizon.Project
  alias Horizon.Project

  describe "new/1" do
    test "creates a new project configuration with given options" do
      opts = [name: "my_project", server_names: ["my-domain.com", "also-mine.io"]]
      project = Project.new(opts)

      assert %Project{
               name: "my_project",
               server_names: ["my-domain.com", "also-mine.io"],
               http_only: false,
               servers: []
             } = project
    end

    test "creates a new project configuration with default values" do
      project = Project.new()

      assert %Project{
               name: nil,
               server_names: [],
               acme_challenge_path: nil,
               http_only: false,
               servers: []
             } = project
    end
  end

  test "sets the static_index_root when given an index" do
    project = Project.new(name: "my_project", static_index: "index.html")

    assert %Project{
             name: "my_project",
             static_index_root: "/usr/local/my_project",
             static_index: "index.html"
           } = project
  end

  test "does not override the static_index_root when given an index" do
    project =
      Project.new(
        name: "my_project",
        static_index: "index.html",
        static_index_root: "/my_project"
      )

    assert %Project{
             name: "my_project",
             static_index_root: "/my_project",
             static_index: "index.html"
           } = project
  end
end
