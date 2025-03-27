# Makefile for Go + LocalStack Lambda + SQS project

# AWS CLI config
AWS_ENDPOINT=http://localhost:4566
QUEUE_NAME=todo-queue
LAMBDA_NAME=my-go-lambda
ZIP_FILE=lambda/function.zip
ROLE_ARN=arn:aws:iam::000000000000:role/lambda-role

.PHONY: all build-lambda zip-lambda create-queue create-lambda map-sqs-to-lambda invoke-lambda start-api reset clean

all: build-lambda zip-lambda create-queue create-lambda map-sqs-to-lambda

# Build Go Lambda binary
build-lambda:
	GOOS=linux GOARCH=amd64 go build -o lambda/main lambda/main.go

# Zip it for deployment
zip-lambda:
	zip -j $(ZIP_FILE) lambda/main

# Create SQS Queue
create-queue:
	aws --endpoint-url=$(AWS_ENDPOINT) sqs create-queue --queue-name $(QUEUE_NAME)

# Deploy Lambda
create-lambda:
	aws --endpoint-url=$(AWS_ENDPOINT) lambda create-function \
	  --function-name $(LAMBDA_NAME) \
	  --runtime go1.x \
	  --handler main \
	  --zip-file fileb://$(ZIP_FILE) \
	  --role $(ROLE_ARN)

# Map SQS queue to Lambda (trigger)
map-sqs-to-lambda:
	aws --endpoint-url=$(AWS_ENDPOINT) lambda create-event-source-mapping \
	  --function-name $(LAMBDA_NAME) \
	  --batch-size 1 \
	  --event-source-arn arn:aws:sqs:us-east-1:000000000000:$(QUEUE_NAME)

# Manually invoke Lambda (for testing)
invoke-lambda:
	echo '{"Records":[{"body":"{\"task\":\"buy milk\"}"}]}' > event.json
	aws --endpoint-url=$(AWS_ENDPOINT) lambda invoke \
	  --function-name $(LAMBDA_NAME) \
	  --payload file://event.json \
	  output.json && cat output.json

# Start HTTP API (must be run locally, not in Docker)
start-api:
	go run api/main.go

# Clean everything
clean:
	rm -f lambda/main $(ZIP_FILE) output.json event.json

# Reset LocalStack state
reset:
	rm -rf .localstack
	docker-compose down -v