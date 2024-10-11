defmodule Horizon.Target do
  @moduledoc """
  ADT for Horizon deployment targets

  """
  @enforce_keys [:executable?, :type, :key]
  defstruct [:executable?, :type, :key]

  # Define all valid target types
  @type type :: :template | :static
  # Define all valid key values
  @type key ::
          :bsd_install
          | :bsd_install_args
          | :bsd_install_script
          | :helpers
          | :stage_for_build
          | :build
          | :build_script
          | :release_on_build

  @type t :: %Horizon.Target{
          executable?: boolean(),
          type: type(),
          key: key()
        }

  def is_static?(%Horizon.Target{type: :static}), do: true
  def is_static?(_), do: false

  def is_template?(%Horizon.Target{type: :template}), do: true
  def is_template?(_), do: false
end
