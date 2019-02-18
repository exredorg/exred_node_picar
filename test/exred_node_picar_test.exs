defmodule Exred.Node.PicarTest do
  use ExUnit.Case
  doctest Exred.Node.Picar

#   use Exred.NodeTest, module: Exred.Node.Picar
# 
#   setup_all do
#     start_node()
#   end
# 
#   test "PWM alive" do
#     assert Process.alive?(Process.whereis(Exred.Node.Picar.PWM))
#   end
#   test "FrontWheels alive" do
#     assert Process.alive?(Process.whereis(Exred.Node.Picar.FrontWheels))
#   end
#   test "RearWheels alive" do
#     assert Process.alive?(Process.whereis(Exred.Node.Picar.RearWheels))
#   end
end
