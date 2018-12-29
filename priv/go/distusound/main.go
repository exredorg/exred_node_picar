package main

import (
	"fmt"
	"os"
	"time"

	"github.com/stianeikeland/go-rpio"
)

func main() {
	fmt.Printf("hello, world\n")
	for i := 0; i < 100; i++ {
		ping()
		time.Sleep(time.Second)
	}
}

func ping() {
	if err := rpio.Open(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer rpio.Close()

	// prepare to emit ping
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

	fmt.Println("start      :", measuringStart)
	fmt.Println("pulse start:", pulseStart)
	fmt.Println("pulse end  :", pulseEnd)
	fmt.Println("Distance (cm) :", distanceCm)
}
