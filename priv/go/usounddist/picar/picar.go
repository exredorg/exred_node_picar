package picar

import (
	"fmt"
	"os"
	"time"
	pb "usd/exredrpc"

	rpio "github.com/stianeikeland/go-rpio"
)

// BondID is the ID that the gRPC client will use to connect to the gRPC Twin node
const BondID = "hellooo"

// Setup opens the connection to the GPIO interface
func setup() {
	if err := rpio.Open(); err != nil {
		fmt.Println(err)
		rpio.Close()
		os.Exit(1)
	}
}

// SendMessages sends messages to the outgoing channel
func SendMessages(outChan chan<- pb.Msg) {
	setup()
	defer rpio.Close()
	for {
		distance := measure()
		msg := pb.Msg{Payload: map[string]string{"distance": fmt.Sprintf("%f", distance)}}
		outChan <- msg

		time.Sleep(time.Second)
	}
}

// HandleMessages handles messages coming from the incoming channel (from the gRPC channel)
func HandleMessages(inChan <-chan pb.Msg) {
	setup()
	defer rpio.Close()
	for {
		msg := <-inChan
		fmt.Println("RECEIVED:", msg)
	}
}

func measure() float64 {
	//rpio.Open()
	pin := rpio.Pin(20)
	pin.Output()
	pin.Low()
	time.Sleep(10 * time.Millisecond)

	// ping
	pin.High()
	time.Sleep(10 * time.Microsecond)
	pin.Low()

	// wait for echo
	measuringStart := time.Now()
	timeout := measuringStart.Add(500 * time.Millisecond)

	pin.Input()
	pin.PullDown()
	pinstate := pin.Read()
	// wait for pin up
	for pinstate == rpio.Low && time.Now().Before(timeout) {
		pinstate = pin.Read()
		time.Sleep(time.Microsecond)
	}
	pulseStart := time.Now()

	// wait for pin down
	for pinstate == rpio.High && time.Now().Before(timeout) {
		pinstate = pin.Read()
		time.Sleep(time.Microsecond)
	}
	pulseEnd := time.Now()

	// calculate distance
	duration := pulseEnd.Sub(pulseStart)
	distanceCm := duration.Seconds() * 304 * 100 / 2

	fmt.Println("Distance (cm) :", distanceCm)

	return distanceCm
}
