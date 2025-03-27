package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
)

var queueURL = "http://localhost:4566/000000000000/todo-queue"

type Todo struct {
	Task string `json:"task"`
}

func main() {
	sess := session.Must(session.NewSession(&aws.Config{
		Region:      aws.String("us-east-1"),
		Endpoint:    aws.String("http://localhost:4566"),
		Credentials: credentials.NewStaticCredentials("test", "test", ""),
	}))
	svc := sqs.New(sess)

	http.HandleFunc("/add-todo", func(w http.ResponseWriter, r *http.Request) {
		var todo Todo
		if err := json.NewDecoder(r.Body).Decode(&todo); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		body, _ := json.Marshal(todo)
		_, err := svc.SendMessage(&sqs.SendMessageInput{
			QueueUrl:    aws.String(queueURL),
			MessageBody: aws.String(string(body)),
		})
		if err != nil {
			log.Println("SendMessage failed:", err)
			http.Error(w, "Failed to enqueue task", http.StatusInternalServerError)
			return
		}

		fmt.Fprintf(w, "Enqueued: %s\n", todo.Task)
	})

	log.Println("Server running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
