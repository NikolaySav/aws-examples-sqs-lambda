package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type Todo struct {
	Task string `json:"task"`
}

func handler(_ context.Context, sqsEvent events.SQSEvent) (string, error) {
	for _, message := range sqsEvent.Records {
		var todo Todo
		if err := json.Unmarshal([]byte(message.Body), &todo); err != nil {
			fmt.Println("Invalid message:", message.Body)
			continue
		}
		fmt.Printf("📥 New Todo: %s\n", todo.Task)
	}
	return "Processed SQS message(s)", nil
}

func main() {
	lambda.Start(handler)
}
