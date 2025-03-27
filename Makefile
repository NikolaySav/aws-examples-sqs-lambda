# Makefile for Go + LocalStack Lambda + SQS project

# AWS CLI config
AWS_ENDPOINT=http://localhost:4566
QUEUE_NAME=todo-queue
LAMBDA_NAME=my-go-lambda
ZIP_FILE=lambda/function.zip
ROLE_ARN=arn:aws:iam::000000000000:role/lambda-role
AWS_REGION=eu-central-1

.PHONY: all build-lambda zip-lambda create-queue create-lambda wait-for-queue map-sqs-to-lambda invoke-lambda start-api reset clean

all: build-lambda zip-lambda create-queue create-lambda wait-for-lambda map-sqs-to-lambda invoke-lambda start-api reset clean
	@echo "🎉 All done! Lambda and SQS are connected and ready."

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
	@echo "🔍 Checking if Lambda already exists..."
	@if aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda get-function --function-name $(LAMBDA_NAME) > /dev/null 2>&1; then \
		echo "✅ Lambda already exists. Skipping creation."; \
	else \
		echo "🚀 Creating Lambda function..."; \
		aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda create-function \
		  --function-name $(LAMBDA_NAME) \
		  --runtime go1.x \
		  --handler main \
		  --zip-file fileb://$(ZIP_FILE) \
		  --role $(ROLE_ARN); \
	fi

wait-for-lambda:
	@echo "🔍 Waiting for Lambda function to exist..."
	@while ! aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda get-function \
	    --function-name $(LAMBDA_NAME) > /dev/null 2>&1; do \
	    echo "  ⏳ Still waiting..."; sleep 1; \
	done
	@echo "✅ Lambda is ready!"

# Map SQS queue to Lambda (trigger)
map-sqs-to-lambda:
	@echo "🔁 Checking for existing event source mappings..."
	@if aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda list-event-source-mappings \
	     --function-name $(LAMBDA_NAME) | grep -q $(QUEUE_NAME); then \
		echo "✅ Mapping already exists."; \
	else \
		echo "🔗 Creating new event source mapping..."; \
		aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda create-event-source-mapping \
			--function-name $(LAMBDA_NAME) \
			--batch-size 1 \
			--event-source-arn arn:aws:sqs:$(AWS_REGION):000000000000:$(QUEUE_NAME); \
	fi

# Manually invoke Lambda (for testing)
invoke-lambda:
	echo '{"Records":[{"body":"{\"task\":\"buy milk\"}"}]}' > event.json
	aws --endpoint-url=$(AWS_ENDPOINT) lambda invoke \
	  --function-name $(LAMBDA_NAME) \
	  --cli-binary-format raw-in-base64-out \
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

localstack-logs:
	docker logs -f localstack

wait-for-queue:
	@echo "⏳ Waiting for SQS queue to be available..."
	@until aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) sqs get-queue-attributes \
	  --queue-url http://localhost:4566/000000000000/$(QUEUE_NAME) \
	  --attribute-names QueueArn > /dev/null 2>&1; do \
	  echo "  ...still waiting"; sleep 1; \
	done
	@echo "✅ Queue is available!"

status:
	@echo "🔍 Lambda functions:"
	@aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda list-functions
	@echo ""
	@echo "🔍 SQS queues:"
	@aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) sqs list-queues
	@echo ""
	@echo "🔍 Event source mappings:"
	@aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION) lambda list-event-source-mappings \
		--function-name $(LAMBDA_NAME)