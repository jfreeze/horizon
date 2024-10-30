defmodule Horizon.ServerTest do
  use ExUnit.Case
  doctest Horizon.Server
  alias Horizon.Server

  describe "new/1" do
    test "creates a new server configuration with default values" do
      assert %Server{internal_ip: "127.0.0.1", port: 4000} = Server.new()
    end

    test "creates a new server configuration with custom values" do
      assert %Server{internal_ip: "10.0.0.2", port: 4001} =
               Server.new(internal_ip: "10.0.0.2", port: 4001)
    end
  end
end
