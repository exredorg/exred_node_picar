defmodule Exred.Node.Picar do
  @moduledoc """
  Controls a SunFounder PiCar.

  Messages:
   %{payload: "stop"}           -> RearWheels.stop()
   %{payload: {"speed", speed}} -> RearWheels.speed(speed)
   %{payload: {"left", angle}}  -> FrontWheels.left(angle)
   %{payload: {"right", angle}} -> FrontWheels.right(angle)
   %{payload: "straight"}       -> FrontWheels.straight()
  """

  @i2c_device "i2c-1"
  @i2c_address 0x40

  @name "PiCar"
  @category "Device"
  @info @moduledoc
  @config %{
    name: %{
      info: "Visible name",
      value: @name,
      type: "string",
      attrs: %{max: 30}
    },
    i2c_device: %{
      info: "I2C device name on the PiCar",
      value: "i2c-1",
      type: "string",
      attrs: %{max: 15}
    },
    i2c_address: %{
      info: "I2C address for the PiCar PWM board (in octal format)",
      value: "0x40",
      type: "string",
      attrs: %{max: 5}
    }
  }
  @ui_attributes %{left_icon: "directions_car"}

  alias Exred.Node.Picar.FrontWheels
  alias Exred.Node.Picar.RearWheels
  require Logger
  use Exred.NodePrototype

  @impl true
  def daemon_child_specs(config) do
    [
      %{
        id: I2C,
        start: {ElixirALE.I2C, :start_link, [@i2c_device, @i2c_address, [name: :i2c]]}
      },
      Exred.Node.Picar.PWM,
      Exred.Node.Picar.RearWheels,
      Exred.Node.Picar.FrontWheels
    ]
  end

  @impl true
  def handle_msg(msg, state) do
    case msg.payload do
      "stop" ->
        RearWheels.stop()

      {"speed", speed} ->
        RearWheels.speed(speed)

      {"left", angle} ->
        FrontWheels.left(angle)

      {"right", angle} ->
        FrontWheels.right(angle)

      "straight" ->
        FrontWheels.straight()

      _ ->
        Logger.warn(
          "UNHANDLED MSG node: #{state.node_id} #{get_in(state.config, [:name, :value])} msg: #{
            inspect(msg)
          }"
        )
    end

    {nil, state}
  end
end
