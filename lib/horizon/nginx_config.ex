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

  require Logger

  @template_path "../../priv/templates/nginx/nginx.conf.eex"
  @default_template_path [__DIR__, @template_path]
                         |> Path.join()
                         |> Path.expand()

  @doc """
  Generates an Nginx configuration file using a templating system.

  ## Examples

      iex> project =   %Horizon.Project{
        name: "example_project",
        server_names: ["example.com", "www.example.com"],
        letsencrypt_live: "mydomain.com",
        acme_challenge_path: "/apps/challenge/mydomain.com",
        http_only: false,
        servers: [
          %Horizon.Server{internal_ip: "10.0.0.1", port: 4000},
          %Horizon.Server{internal_ip: "10.0.0.2", port: 4001}
        ]
      }
      iex>Horizon.NginxConfig.generate([project])

  """
  @spec generate([Horizon.Project.t()]) :: String.t()
  def generate(projects) when is_list(projects) do
    project_template_path = "priv/horizon/templates/nginx.conf.eex"

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

  @doc """
  Returns the path for the certificate

  ## Examples
      iex>cert_path(%Horizon.Project{certificate: :self, cert_path: "/path/to/cert.pem"})
      "/path/to/cert.pem"

      iex>cert_path(%Horizon.Project{certificate: :letsencrypt, domain: "example.com"})
      "/user/local/etc/letsencrypt/live/example.com/fullchain.pem"

  """
  @spec cert_path(Horizon.Project.t()) :: String.t()
  def cert_path(%Horizon.Project{
        certificate: :letsencrypt,
        letsencrypt_domain: domain
      })
      when is_binary(domain) do
    "/usr/local/etc/letsencrypt/live/#{domain}/fullchain.pem"
  end

  def cert_path(%Horizon.Project{certificate: :letsencrypt, cert_path: path}), do: path

  def cert_path(%Horizon.Project{certificate: :self, cert_path: path}), do: path

  @doc """
  Returns the path for the certificate

  ## Examples
      iex>cert_key_path(%Horizon.Project{certificate: :self, cert_key_path: "/path/to/cert_key.pem"})
      "/path/to/cert_key.pem"

      iex>cert_key_path(%Horizon.Project{certificate: :letsencrypt, domain: "example.com"})
      "/user/local/etc/letsencrypt/live/example.com/privkey.pem"

  """
  @spec cert_key_path(Horizon.Project.t()) :: String.t()
  def cert_key_path(%Horizon.Project{
        certificate: :letsencrypt,
        letsencrypt_domain: domain
      })
      when is_binary(domain) do
    "/usr/local/etc/letsencrypt/live/#{domain}/privkey.pem"
  end

  def cert_key_path(%Horizon.Project{certificate: :letsencrypt, cert_key_path: path}), do: path

  def cert_key_path(%Horizon.Project{certificate: :self, cert_key_path: path}), do: path

  @nginxconf_path "/usr/local/etc/nginx/nginx.conf"

  @doc """
  Sends the Nginx configuration to a remote host and reloads the Nginx service.

  ## Example

      iex>user = "me"
      iex>host = "myhost"
      iex>projects = [%Horizon.Project{name: "my project", ...}]
      iex>NginxConfig.send(projects, user, host)
      iex>NginxConfig.send(projects, user, host, nginxconf_path: "/usr/nginx/nginx.conf", action: :restart)

  """
  @spec send([Horizon.Project.t()], String.t(), String.t(), keyword()) ::
          {:ok, any()} | {:error, non_neg_integer(), any()}
  def send(
        projects,
        user,
        host,
        opts \\ []
      ) do
    nginxconf_path = Keyword.get(opts, :nginxconf_path, @nginxconf_path)
    action = Keyword.get(opts, :action, :reload)

    encoded_content =
      projects
      |> Horizon.NginxConfig.generate()
      |> :base64.encode()

    command =
      "echo #{encoded_content} | ssh #{user}@#{host} 'base64 -d | doas tee #{nginxconf_path} > /dev/null && doas service nginx #{action}'"

    case System.cmd("sh", ["-c", command]) do
      {result, 0} ->
        Logger.info("Nginx configuration sent to #{host}")
        {:ok, result}

      {result, exit_code} ->
        Logger.error("Failed to update Nginx configuration. Exit code #{exit_code}. #{result}")

        {:error, exit_code, result}
    end
  end
end
