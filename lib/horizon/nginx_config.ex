defmodule Horizon.NginxConfig do
  @moduledoc ~S"""
  Generates an Nginx configuration file using a templating system.
  Allows for template overrides in the current project.
  The configuration is based on Horizon.Project and Horizon.Server.

  ## Customizing the Nginx configuration template

  To customize your `nginx.conf`, copy the template from the Horizon package to your project:

      $ mkdir -p priv/horizon/templates
      $ cp deps/horizon/priv/templates/nginx/nginx.conf.eex priv/horizon/templates/nginx.conf.eex

  ## Running the generator from iex

  ## Examples


  ```elixir
  user = "username"
  host = "host-address"
  remote_path = "/usr/local/etc/nginx/nginx.conf"

  projects = [
    %Horizon.Project{
      name: "project-name",
      server_names: ["my.server.com"],
      http_only: true,
      servers: [
        %Horizon.Server{internal_ip: "127.0.0.1", port: 4000},
        %Horizon.Server{internal_ip: "192.168.100.100", port: 4000}
      ]
    }
  ]

  config_output = Horizon.NginxConfig.generate(projects)
  encoded_content = :base64.encode(config_output)
  command = "echo #{encoded_content} | ssh #{user}@#{host} 'base64 -d | doas tee #{remote_path} > /dev/null && doas service nginx reload'"
  {result, exit_code} = System.cmd("sh", ["-c", command])
  ```
  """

  @template_path "../../priv/templates/nginx/nginx.conf.eex"
  @default_template_path Path.join([__DIR__, @template_path])
                         |> Path.expand()

  @doc """
  Generates an Nginx configuration file using a templating system.

  ## Examples

      iex> project =   %Horizon.Project{
        name: "example_project",
        server_names: ["example.com", "www.example.com"],
        letsencrypt_live: "mydomain.com",
        acme_challenge_path: "/apps/challenge/mydomain.com",
        suppress_ssl: false,
        servers: [
          %Horizon.Server{internal_ip: "10.0.0.1", port: 4000},
          %Horizon.Server{internal_ip: "10.0.0.2", port: 4001}
        ]
      }
      iex>Horizon.NginxConfig.generate([project])

  """
  @spec generate([Horizon.Project.t()]) :: :ok
  def generate(projects) when is_list(projects) do
    app_name = current_app_name()

    project_template_path =
      Path.join([:code.priv_dir(app_name), "horizon/templates/nginx.conf.eex"])

    template_path =
      if File.exists?(project_template_path) do
        project_template_path
      else
        @default_template_path
      end

    template_path
    |> File.read!()
    |> EEx.eval_string(projects: projects)
  end

  # Dynamically get the current application name
  defp current_app_name do
    case Application.get_application(__MODULE__) do
      nil -> raise "ERROR: Could not determine the current application name"
      app -> app
    end
  end
end
