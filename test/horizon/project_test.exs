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
               ssl_certificate: nil,
               acme_challenge_path: nil,
               suppress_ssl: false,
               servers: []
             } = project
    end

    test "creates a new project configuration with default values" do
      project = Project.new()

      assert %Project{
               name: nil,
               server_names: nil,
               ssl_certificate: nil,
               acme_challenge_path: nil,
               suppress_ssl: false,
               servers: []
             } = project
    end
  end
end
