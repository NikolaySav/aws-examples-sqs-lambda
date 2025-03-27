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

func handler(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, message := range sqsEvent.Records {
		var todo Todo
		if err := json.Unmarshal([]byte(message.Body), &todo); err != nil {
			fmt.Println("Invalid message:", message.Body)
			continue
		}
		fmt.Printf("📥 New Todo: %s\n", todo.Task)
	}
	return nil
}

func main() {
	lambda.Start(handler)
}
