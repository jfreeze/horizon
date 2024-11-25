defmodule Horizon.Project do
  @moduledoc """
    Project configuration for web based projects.

    - `server_names` - List of recognized host names that can be received by nginx.
    - `certificate` - The certificate to use for the project. Can be `nil`, `:self`, or `:letsencrypt`.
    - `authenticator` - The authenticator to use for the project. Can be `nil` or a string, e.g. "webroot".
    - `cert_path` - Overrides the path to the certificate file.
    - `cert_key_path` - Overrides the path to the certificate key file.
    - `letsencrypt_domain` - The domain to use for the letsencrypt certificate.
    - `acme_challenge_path` - The root path to the acme challenge directory.
    - `http_only` - If true, only the http clause will be defined.
    - `servers` - List of servers to proxy to.

    ## Examples

        #iex> projects = [
          %Horizon.Project{
            name: "my_app1",
            server_names: ["http-demo"],
            http_only: true,
            # certificate: :letsencrypt,
            # letsencrypt_domain: "my_app",
            servers: [
              # Verify PORT is same as in runtime.exs or env.sh.eex
              %Horizon.Server{internal_ip: "127.0.0.1", port: 4000},
              %Horizon.Server{internal_ip: "10.0.0.5", port: 4000}
            ]
          },
          %Horizon.Project{
            name: "my_app2",
            server_names: ["https-demo"],
            certificate: :self,
            servers: [
              # Verify PORT is same as in runtime.exs or env.sh.eex
              %Horizon.Server{internal_ip: "127.0.0.1", port: 5000},
              %Horizon.Server{internal_ip: "10.0.0.5", port: 5000}
            ]
          }
        ]

  """

  @type cert :: nil | :self | :letsencrypt

  defstruct name: nil,
            server_names: nil,
            certificate: nil,
            authenticator: nil,
            cert_path: nil,
            cert_key_path: nil,
            letsencrypt_domain: nil,
            acme_challenge_path: nil,
            http_only: false,
            servers: []

  @type t :: %__MODULE__{
          name: String.t(),
          server_names: [String.t()],
          certificate: cert(),
          authenticator: String.t() | nil,
          cert_path: String.t() | nil,
          cert_key_path: String.t() | nil,
          letsencrypt_domain: String.t() | nil,
          acme_challenge_path: String.t() | nil,
          http_only: boolean(),
          servers: [Horizon.Server.t()]
        }

  @doc """
  Create a new project configuration.

  ## Examples

      iex> Horizon.Project.new(name: "my_project", server_names: ["my-domain.com", "also-mine.io"])
      %Horizon.Project{
        name: "my_project",
        server_names: ["my-domain.com", "also-mine.io"],
        certificate: nil,
        acme_challenge_path: nil,
        http_only: false,
        servers: []
      }

  """
  @spec new(list()) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end
end
