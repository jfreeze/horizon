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
               letsencrypt_live: nil,
               acme_challenge_path: nil,
               http_only: false,
               servers: []
             } = project
    end

    test "creates a new project configuration with default values" do
      project = Project.new()

      assert %Project{
               name: nil,
               server_names: nil,
               letsencrypt_live: nil,
               acme_challenge_path: nil,
               http_only: false,
               servers: []
             } = project
    end
  end
end
