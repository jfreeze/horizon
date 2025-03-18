defmodule Horizon.NginxConfig do
  @moduledoc ~S"""
  This module generates an Nginx configuration file using a templating system.
  Allows for template overrides in the current project.
  The configuration is based on `Horizon.Project` and `Horizon.Server`.

  ## Customizing the Nginx configuration template

  To customize your `nginx.conf`, copy the template from the Horizon package to your project:

      $ mkdir -p priv/horizon/templates
      $ cp deps/horizon/priv/templates/nginx/nginx.conf.eex priv/horizon/templates/nginx.conf.eex

  You can also customize individual blocks of the configuration file:

      $ cp deps/horizon/priv/templates/nginx/_upstream.eex priv/horizon/templates/_upstream.eex
      $ cp deps/horizon/priv/templates/nginx/_server_http.eex priv/horizon/templates/_server_http.eex
      $ cp deps/horizon/priv/templates/nginx/_server_https.eex priv/horizon/templates/_server_https.eex

  ## Nginx Header Options

      * `:client_max_body_size` - Maximum allowed size of the client request body (default: "6M")
      * `:sendfile` - Enable or disable sendfile usage (default: true)
      * `:keepalive_timeout` - Timeout during which a keep-alive client connection will stay open (default: 65)
      * `:gzip` - Enable or disable gzip compression (default: true)
      * `:access_log` - Enable or disable access logging (default: true)
      * `:access_log_path` - Path to the access log file (default: "/var/log/nginx/access.log")
      * `:worker_connections` - Maximum number of simultaneous connections that can be opened by a worker process (default: 1024)

  ## Examples

      iex> project = %Horizon.Project{
      ...>   name: "example_project",
      ...>   server_names: ["example.com", "www.example.com"],
      ...>   letsencrypt_domain: "mydomain.com",
      ...>   acme_challenge_path: "/apps/challenge/mydomain.com",
      ...>   http_only: false,
      ...>   servers: [
      ...>     %Horizon.Server{internal_ip: "10.0.0.1", port: 4000},
      ...>     %Horizon.Server{internal_ip: "10.0.0.2", port: 4001}
      ...>   ]
      ...> }
      iex> Horizon.NginxConfig.generate([project])

  With custom options:

      iex> Horizon.NginxConfig.generate([project],
      ...>   client_max_body_size: "20M",
      ...>   worker_connections: 2048,
      ...>   gzip: false
      ...> )


  ```elixir
  user_host = "username@host-address"
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

  config_output = Horizon.NginxConfig.send(projects)
  ```
  """

  require Logger

  @template_root "../../priv/templates/nginx"
  @project_root "priv/horizon/templates"
  @templates %{
    :nginx => "nginx.conf.eex",
    :upstream => "_upstream.eex",
    :server_http => "_server_http.eex",
    :server_https => "_server_https.eex"
  }

  @type nginx_options :: [
          client_max_body_size: String.t(),
          sendfile: boolean(),
          keepalive_timeout: integer(),
          gzip: boolean(),
          access_log: boolean(),
          access_log_path: String.t(),
          worker_connections: integer()
        ]

  @default_options [
    client_max_body_size: "6M",
    sendfile: true,
    keepalive_timeout: 65,
    gzip: true,
    access_log: true,
    access_log_path: "/var/log/nginx/access.log",
    worker_connections: 1024
  ]

  @doc """
  Generates an Nginx configuration file as a string based on the provided projects and options.

  This function takes a list of `Horizon.Project.t()` structures and optional Nginx configuration
  options, merges the provided options with defaults, and generates a formatted Nginx
  configuration string using the appropriate template.

  ## Parameters

    * `projects` - A list of `Horizon.Project.t()` structures defining the applications to be configured
    * `opts` - A keyword list of Nginx configuration options (see "Nginx Header Options" in module documentation)

  ## Returns

    * A formatted Nginx configuration as a string
    * An empty string if the projects list is empty

  ## Examples

      iex> projects = [
      ...>   %Horizon.Project{
      ...>     name: "my_app",
      ...>     server_names: ["example.com"],
      ...>     servers: [%Horizon.Server{internal_ip: "127.0.0.1", port: 4000}]
      ...>   }
      ...> ]
      iex> Horizon.NginxConfig.generate(projects)

      # With custom options
      iex> Horizon.NginxConfig.generate(projects, client_max_body_size: "20M", gzip: false)
  """
  @spec generate([Horizon.Project.t()], nginx_options()) :: String.t()
  def generate(projects, opts \\ [])

  def generate([], _opts), do: ""

  def generate(projects, opts) when is_list(projects) do
    opts = Keyword.merge(@default_options, opts)

    :nginx
    |> template_path()
    |> File.read!()
    |> EEx.eval_string(projects: projects, opts: opts)
    |> Horizon.SimpleNginxFormatter.format()
  end

  defp template_path(key) do
    file = @templates[key]

    template =
      [__DIR__, Path.join(@template_root, file)]
      |> Path.join()
      |> Path.expand()

    project_template =
      [@project_root, file]
      |> Path.join()
      |> Path.expand()

    if File.exists?(project_template) do
      project_template
    else
      template
    end
  end

  @doc """
  Returns the path for the certificate

  ## Examples
      iex> cert_path(%Horizon.Project{certificate: :self, cert_path: "/path/to/cert.pem"})
      "/path/to/cert.pem"

      iex> cert_path(%Horizon.Project{certificate: :letsencrypt, domain: "example.com"})
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

  def cert_path(%Horizon.Project{name: name, certificate: :self, cert_path: nil}) do
    "/usr/local/#{name}/cert/selfsigned.pem"
  end

  def cert_path(%Horizon.Project{certificate: :self, cert_path: path}), do: path

  def cert_path(%Horizon.Project{}), do: nil

  @doc """
  Returns the path for the certificate

  ## Examples
      iex> cert_key_path(%Horizon.Project{
      ...>   certificate: :self,
      ...>   cert_key_path: "/path/to/cert_key.pem"
      ...> })
      "/path/to/cert_key.pem"

      iex> cert_key_path(%Horizon.Project{certificate: :letsencrypt, domain: "example.com"})
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

  def cert_key_path(%Horizon.Project{name: name, certificate: :self, cert_key_path: nil}) do
    "/usr/local/#{name}/cert/selfsigned_key.pem"
  end

  def cert_key_path(%Horizon.Project{certificate: :self, cert_key_path: path}), do: path

  def cert_key_path(%Horizon.Project{}), do: nil

  @nginxconf_path "/usr/local/etc/nginx/nginx.conf"

  @doc """
  Sends the Nginx configuration to a remote host and reloads the Nginx service.

  ## Options

  * `:nginxconf_path` - Path to nginx.conf on the remote host (default: "/usr/local/etc/nginx/nginx.conf")
  * `:action` - Action to take on the remote host after updating config (:reload or :restart) (default: :reload)
  * `:nginx` - Nginx configuration options (see `generate/2` for available options)

  ## Examples

      iex> user_host = "me@myhost"
      ...> projects = [%Horizon.Project{name: "my project", ...}]
      ...> NginxConfig.send(projects, user_host)

      # With custom nginx.conf path and restart action
      iex> NginxConfig.send(projects, user_host,
      ...>   nginxconf_path: "/usr/nginx/nginx.conf",
      ...>   action: :restart
      ...> )

      # With custom nginx options
      iex> NginxConfig.send(projects, user_host,
      ...>   nginx: [
      ...>     client_max_body_size: "20M",
      ...>     worker_connections: 2048
      ...>   ]
      ...> )

  """
  @spec send([Horizon.Project.t()], String.t(), keyword()) ::
          {:ok, any()} | {:error, non_neg_integer(), any()}
  def send(
        projects,
        user_host,
        opts \\ []
      ) do
    nginxconf_path = Keyword.get(opts, :nginxconf_path, @nginxconf_path)
    action = Keyword.get(opts, :action, :reload)
    nginx_opts = Keyword.get(opts, :nginx, [])

    encoded_content =
      projects
      |> Horizon.NginxConfig.generate(nginx_opts)
      |> :base64.encode()

    command =
      "echo #{encoded_content} | ssh #{user_host} 'base64 -d | doas tee #{nginxconf_path} > /dev/null && doas service nginx #{action}'"

    case System.cmd("sh", ["-c", command]) do
      {result, 0} ->
        Logger.info("Nginx configuration sent to #{user_host}")
        {:ok, result}

      {result, exit_code} ->
        Logger.error("Failed to update Nginx configuration. Exit code #{exit_code}. #{result}")

        {:error, exit_code, result}
    end
  end

  @spec render_partial(atom(), keyword()) :: String.t()
  def render_partial(partial_name, assigns) do
    partial_path = template_path(partial_name)
    EEx.eval_file(partial_path, assigns)
  end
end
