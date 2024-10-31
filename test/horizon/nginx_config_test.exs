defmodule Horizon.NginxConfigTest do
  use ExUnit.Case
  alias Horizon.NginxConfig

  @sample_template """
  server {
    listen 80;
    server_name <%= Enum.map(projects, & &1.name) |> Enum.join(", ") %>;
  }
  """

  @sample_projects [
    %Horizon.Project{name: "project1"},
    %Horizon.Project{name: "project2"}
  ]

  setup do
    # Mock the file reading to return the sample template
    File.mkdir_p("priv/horizon/templates/")
    File.write!("priv/horizon/templates/nginx.conf.eex", @sample_template)

    # Ensure the file is cleaned up after the test
    on_exit(fn ->
      File.rm!("priv/horizon/templates/nginx.conf.eex")
    end)

    :ok
  end

  test "generate/1 outputs the correct nginx config" do
    expected_output = """
    server {
      listen 80;
      server_name project1, project2;
    }

    """

    output =
      capture_io(fn ->
        NginxConfig.generate(@sample_projects)
      end)

    assert output == expected_output
  end
end
