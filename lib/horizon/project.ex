defmodule Horizon.Project do
  @moduledoc """
  Project configuration for web based projects.
  """

  @type cert :: [nil | :self | :letsencrypt]

  defstruct name: nil,
            server_names: nil,
            certificate: nil,
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
          cert_path: String.t(),
          cert_key_path: String.t(),
          letsencrypt_domain: String.t(),
          acme_challenge_path: String.t(),
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
        http_only: true,
        servers: []
      }

  """
  @spec new(list()) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end
end
