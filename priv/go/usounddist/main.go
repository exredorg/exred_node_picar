package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"math/rand"
	"time"
	pb "usd/exredrpc"
	worker "usd/picar"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

const gRPCServerAddress = "localhost:10001"

func init() {
	rand.Seed(time.Now().UnixNano())
}

func randWord(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

var (
	letters = []rune("ABCDEFGHIJKLMNO")

	// channel for exit message
	waitc = make(chan struct{})

	// channels for incoming / outgoing messages
	incoming = make(chan pb.Msg)
	outgoing = make(chan pb.Msg)
)

func main() {
	testFlag := flag.Bool("test", false, "test without sending data to the gRPC server")
	flag.Parse()
	if *testFlag {
		fmt.Println("RUNNING IN TEST MODE")
		testing()
	}

	// set up a connection to the grpc server
	conn, err := grpc.Dial(gRPCServerAddress, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("cound not connect: %v", err)
	}
	defer conn.Close()

	// get a client for the MessageBus service
	client := pb.NewMessageBusClient(conn)

	// create metadata for the RPC request
	md := metadata.New(map[string]string{"bondId": worker.BondID})
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	// initiate request
	rpcChatStream, err := client.Chat(ctx)
	if err != nil {
		log.Fatalf("could not get stream: %v", err)
	}

	// start sending and receiving goroutines
	// these transfer messages between the RPC streams and the incoming and outgoing channels
	go receiveMsg(incoming, rpcChatStream)
	go sendMsg(outgoing, rpcChatStream)

	go worker.HandleMessages(incoming)
	go worker.SendMessages(outgoing)

	// handle messages from the incoming channel
	// go handleMsg(incoming)

	// send some test data
	// sendUpdates(outgoing)

	// wait for RPC call end
	<-waitc
	rpcChatStream.CloseSend()
}

// takes messages from the outgoing channel and sends them out on the gRPC stream
func sendMsg(outChan <-chan pb.Msg, stream pb.MessageBus_ChatClient) {
	for {
		msg := <-outChan
		err := stream.Send(&msg)
		if err != nil {
			log.Fatalf("Failed to send msg: %v\n", msg)
		}
	}
}

// receive messages from the gRPC stream and publish them to the incoming channnel
func receiveMsg(inChan chan<- pb.Msg, stream pb.MessageBus_ChatClient) {
	for {
		in, err := stream.Recv()
		if err == io.EOF {
			fmt.Println("IN  EOF")
			close(waitc)
			return
		}
		if err != nil {
			log.Fatalf("Failed to receive a message: %v\n", err)
		}
		fmt.Printf("IN  payload: %+v\n", in.Payload)
		inChan <- *in
	}
}

// sends updates to the outgoing channel
func sendUpdates(outChan chan<- pb.Msg) {
	messages := []*pb.Msg{
		{Payload: map[string]string{"from": "zsolt"}},
		{Payload: map[string]string{"from": "joe"}},
	}

	for {
		for _, msg := range messages {
			outChan <- *msg
			time.Sleep(time.Second)
		}
		time.Sleep(5 * time.Second)
	}
}

// handles incoming messages
func handleMsg(inChan <-chan pb.Msg) {
	for {
		msg := <-inChan
		fmt.Println("RECEIVED:", msg)
	}
}

func testing() {
	go func(ch <-chan pb.Msg) {
		for {
			fmt.Println(<-ch)
		}
	}(outgoing)
	worker.SendMessages(outgoing)
}
