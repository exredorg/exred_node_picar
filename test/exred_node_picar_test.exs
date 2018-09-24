defmodule Exred.Node.PicarTest do
  use ExUnit.Case
  doctest Exred.Node.Picar

  test "greets the world" do
    assert Exred.Node.Picar.hello() == :world
  end
end
