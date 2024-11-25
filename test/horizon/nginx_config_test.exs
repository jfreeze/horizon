defmodule Horizon.NginxConfigTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Horizon.NginxConfig

  @sample_template """
  server {
    listen 80;
    server_name <%= Enum.map(projects, & &1.name) |> Enum.join(", ") %>;
  }
  """
  @sample_template_with_http_only """
  <%= for project <- projects do %>server {
    listen 80;
    server_names <%= project.server_names %>;
    <%= if project.http_only do %>http_only;<% end %>
  <%= if project.acme_challenge_path do %>location /.well-known/acme-challenge/ {
      root <%= project.acme_challenge_path %>;
    }<% end %>
  }<% end %>
  """

  @sample_projects [
    %Horizon.Project{name: "project1"},
    %Horizon.Project{name: "project2"}
  ]

  setup do
    # Ensure the file is cleaned up after the test
    on_exit(fn ->
      File.rm!("priv/horizon/templates/nginx.conf.eex")
    end)

    :ok
  end

  defp write_sample_template(template) do
    File.mkdir_p("priv/horizon/templates/")
    # Mock the file reading to return the sample template
    File.write!("priv/horizon/templates/nginx.conf.eex", template)
  end

  test "generate/1 outputs the correct nginx config" do
    write_sample_template(@sample_template)

    expected_output = """
    server {
      listen 80;
      server_name project1, project2;
    }
    """

    output = NginxConfig.generate(@sample_projects)

    assert output == expected_output
  end

  test "generate/1 with multiple servers and http_only: true" do
    write_sample_template(@sample_template_with_http_only)

    projects = [
      %Horizon.Project{name: "project1"},
      %Horizon.Project{name: "project2"}
    ]

    expected_output =
      "server {\n  listen 80;\n  server_names ;\n  \n\n}server {\n  listen 80;\n  server_names ;\n  \n\n}\n"

    output = NginxConfig.generate(projects)

    assert output == expected_output
  end

  test "generate/1 with multiple servers and acme_challenge_path" do
    write_sample_template(@sample_template_with_http_only)

    projects = [
      %Horizon.Project{name: "project1", server_names: "a"},
      %Horizon.Project{name: "project2", server_names: "b", acme_challenge_path: "/var/www/acme"}
    ]

    expected_output =
      "server {\n  listen 80;\n  server_names a;\n  \n\n}server {\n  listen 80;\n  server_names b;\n  \nlocation /.well-known/acme-challenge/ {\n    root /var/www/acme;\n  }\n}\n"

    output = NginxConfig.generate(projects)

    assert output == expected_output
  end

  test "generate/1 with multiple servers, http_only: true, and acme_challenge_path" do
    write_sample_template(@sample_template_with_http_only)

    projects = [
      %Horizon.Project{
        name: "project1",
        server_names: "server1,server2",
        http_only: true,
        servers: [%Horizon.Server{}, %Horizon.Server{}]
      }
    ]

    expected_output = """
    server {
      listen 80;
      server_names server1,server2;
      http_only;

    }
    """

    output = NginxConfig.generate(projects)

    IO.puts(output)
    assert output == expected_output
  end

  test "generate/1 with multiple servers and no optional fields" do
    write_sample_template(@sample_template_with_http_only)

    projects = [
      %Horizon.Project{name: "project1"},
      %Horizon.Project{name: "project2"}
    ]

    expected_output =
      "server {\n  listen 80;\n  server_names ;\n  \n\n}server {\n  listen 80;\n  server_names ;\n  \n\n}\n"

    output = NginxConfig.generate(projects)
    assert output == expected_output
  end
end
