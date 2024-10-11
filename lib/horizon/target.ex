defmodule Horizon.Target do
  @moduledoc """
  ADT for Horizon deployment targets

  """
  @enforce_keys [:executable?, :type, :key]
  defstruct [:executable?, :type, :key]

  # Define all valid target types
  @type content_type :: :template | :static
  # Define all valid key values
  @type key ::
          :bsd_install
          | :bsd_install_args
          | :bsd_install_script
          | :horizon_helpers
          | :stage_for_build
          | :build
          | :build_script
          | :release_on_build
          | :rc_d

  @type t :: %Horizon.Target{
          executable?: boolean(),
          type: content_type(),
          key: key()
        }

  @spec is_static?(t) :: boolean()
  def is_static?(%Horizon.Target{type: :static}), do: true
  def is_static?(_), do: false

  @spec is_template?(t) :: boolean()
  def is_template?(%Horizon.Target{type: :template}), do: true
  def is_template?(_), do: false
end
