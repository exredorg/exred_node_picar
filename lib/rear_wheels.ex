defmodule Exred.Node.Picar.RearWheels do

  require Logger
  use GenServer
  alias Exred.Node.Picar.PWM
  alias ElixirALE.GPIO


  @pwma  4                 # pwm channel for motor a
  @pwmb  5
  @motor_a_dir_gpio 17     # gpio pin to control motor direction
  @motor_b_dir_gpio 27
  @forward 0
  @backward 1



  # API
  #####################

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def speed do
    GenServer.call(__MODULE__, {:set_speed, speed})
  end 


  # Callbacks
  #####################

  @impl true
  def init(_args) do
    Logger.debug "Starting..."

    state = %{
      gpio_pid_motor_a: None,
      gpio_pid_motor_b: None,
      freq: 60,
      speed: 0,
      target_speed: 0
    }

    PWM.prescale(state.freq)
    PWM.set(@pwma, 0, 0)
    PWM.set(@pwmb, 0, 0)

    {:ok, gpio_pid_motor_a} = GPIO.start_link @motor_a_dir_gpio, :output
    {:ok, gpio_pid_motor_b} = GPIO.start_link @motor_b_dir_gpio, :output
    GPIO.write gpio_pid_motor_a, @forward
    GPIO.write gpio_pid_motor_b, @forward

    {:ok, %{state | gpio_pid_motor_a: gpio_pid_motor_a, gpio_pid_motor_b: gpio_pid_motor_b}, 200}
  end 

  @impl true
  def handle_info(:timeout, %{speed: speed, target_speed: speed} = state) do
    {:noreply, state, 200}
  end
  
  def handle_info(:timeout, %{speed: speed, target_speed: target} = state) do
    # calculate a possible new speed value
    proposed = speed + (target-speed)/abs(target-speed) * 5
    
    # if proposed is close to the target then skip straight to the target
    new_speed = if abs(target-proposed) < 5 do
      target
    else
      proposed
    end
    
    # set new speed
    PWM.set(@pwma, 0, pulse_width(new_speed))
    PWM.set(@pwmb, 0, pulse_width(new_speed))
    
    # change direction if speed value goes from positive to negative or vice versa
    cond do
      speed > 0 and new_speed < 0 ->
        GPIO.write gpio_pid_motor_a, @backward
        GPIO.write gpio_pid_motor_b, @backward
      speed < 0 and new_speed > 0 ->
          GPIO.write gpio_pid_motor_a, @forward
          GPIO.write gpio_pid_motor_b, @forward
      true ->
        :pass
    end
    {:noreply, %{state | speed: new_speed}, 200}
  end


  @impl true
  def handle_call(:stop, _from, state) do
    PWM.set(@pwma, 0, 0)
    PWM.set(@pwmb, 0, 0)

    reply = {:ok, %{speed: 0}}
    new_state =  %{state | speed: 0, target_speed: 0}
    {:reply, reply, new_state, 200}
  end

  # change the target speed
  def handle_call({:set_speed, target_speed}, _from, state) do
    Logger.debug "Speed target set to #{target_speed}"
    {:reply, :ok, %{state | target_speed: target_speed}, 200}
  end

  # max pulse width on the PCA9685 PWM Driver is 4096
  #
  # absolute speed range is 0-100 
  # (this is just an arbitrary pick, speed range could be anything as long as
  # we correctly map it to the 0-4096 pulse width range )
  #
  # we use the signum of the speed to indicate direction so to calculate 
  # pulse width we need the absolute of speed
  defp pulse_width(speed) when speed>=0 and speed<=100, do: abs(speed) * 40

end

