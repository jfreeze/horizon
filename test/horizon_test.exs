defmodule HorizonTest do
  use ExUnit.Case
  doctest Horizon

  test "greets the world" do
    assert Horizon.hello() == :world
  end
end
