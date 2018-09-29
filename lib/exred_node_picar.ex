defmodule Exred.Node.Picar do
  @moduledoc """
  Controls a SunFounder PiCar.
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


  alias Exred.Scheduler.DaemonNodeSupervisor
  alias Exred.Node.Picar.FrontWheels
  alias Exred.Node.Picar.RearWheels

  use Exred.Library.NodePrototype
  
  require Logger


  @impl true
  def node_init(state) do
    children = [
      %{
        id: I2C,
        start: {ElixirALE.I2C, :start_link, [@i2c_device, @i2c_address, [name: :i2c]]}
        #start: {ElixirALE.I2C, :start_link, [state.config.i2c_device.value, state.config.i2c_address.value, [name: :i2c]]}
      },
      Exred.Node.Picar.PWM,
      Exred.Node.Picar.RearWheels,
      Exred.Node.Picar.FrontWheels
    ]

    # start children
    Enum.each children, fn(child) ->
      case DaemonNodeSupervisor.start_child(child) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, other} ->
          event = "notification"
          debug_data = %{msg: "Could not initialize " <> @name}
          event_msg = %{node_id: state.node_id, node_name: @name, debug_data: debug_data}
          EventChannelClient.broadcast event, event_msg
      end
    end

    state
  end

  @impl true
  def handle_msg(msg, state) do
    case msg.payload do
      "stop" ->
        RearWheels.stop
      "faster" ->
        RearWheels.faster
      "slower" ->
        RearWheels.slower
      "forward" ->
        RearWheels.forward
      "backward" -> 
        RearWheels.backward
      {"left", angle} ->
        FrontWheels.left angle
      {"right", angle} ->
        FrontWheels.right angle
      "straight" -> 
        FrontWheels.straight
      _ ->
         Logger.warn "UNHANDLED MSG node: #{state.node_id} #{get_in(state.config, [:name, :value])} msg: #{inspect msg}"
    end
    {nil, state}
  end

end
