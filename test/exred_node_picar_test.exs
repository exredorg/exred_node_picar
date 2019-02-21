defmodule Exred.Node.PicarTest do
  use ExUnit.Case
  doctest Exred.Node.Picar

  use Exred.NodeTest, module: Exred.Node.Picar

  @tag :rpi
  test "PWM, FrontWheel, RearWheel process alive" do
    start_node()
    assert Process.alive?(Process.whereis(Exred.Node.Picar.PWM))
    assert Process.alive?(Process.whereis(Exred.Node.Picar.FrontWheels))
    assert Process.alive?(Process.whereis(Exred.Node.Picar.RearWheels))
  end
end
