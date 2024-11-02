defmodule Horizon.Server do
  @moduledoc """
  Server configuration to define upstream servers for nginx.conf.
  """

  defstruct internal_ip: "127.0.0.1", port: 4000

  @type t :: %__MODULE__{
          internal_ip: String.t(),
          port: integer()
        }

  @doc """
  Create a new server configuration.

  ## Examples

      iex> Horizon.Server.new()
      %Horizon.Server{internal_ip: "127.0.0.1", port: 4000}
      iex> Horizon.Server.new internal_ip: "10.0.0.2", port: 4001
      %Horizon.Server{internal_ip: "10.0.0.2", port: 4001}

  """
  @spec new(list()) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end
end
