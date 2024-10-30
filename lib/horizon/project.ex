defmodule Horizon.Project do
  @moduledoc """
  Project configuration for web based projects.
  """

  defstruct name: nil,
            server_names: nil,
            letsencrypt_live: nil,
            acme_challenge_path: nil,
            suppress_ssl: false,
            servers: []

  @type t :: %__MODULE__{
          name: String.t(),
          server_names: [String.t()],
          letsencrypt_live: String.t(),
          acme_challenge_path: String.t(),
          suppress_ssl: boolean(),
          servers: [Horizon.Server.t()]
        }

  @doc """
  Create a new project configuration.

  ## Examples

      iex> Horizon.Project.new(name: "my_project", server_names: ["my-domain.com", "also-mine.io"])
      %Horizon.Project{
        name: "my_project",
        server_names: ["my-domain.com", "also-mine.io"],
        letsencrypt_live: nil,
        acme_challenge_path: nil,
        suppress_ssl: false,
        servers: []
      }

  """
  @spec new(list()) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end
end
