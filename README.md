# 📨 AWS SQS + Lambda Integration (Go + LocalStack)

This project demonstrates how to build an AWS Lambda in Go that processes messages from an SQS queue — all running **locally** using [LocalStack](https://github.com/localstack/localstack).

---

## 📦 Project Overview

- **Language**: Go
- **Infrastructure**: AWS Lambda + SQS
- **Runtime**: go1.x
- **Environment**: LocalStack (Docker)
- **Trigger**: SQS → Lambda

---

## 🛠️ Prerequisites

Ensure you have the following installed:

- [Docker](https://www.docker.com/)
- [Go](https://golang.org/) (v1.20+ recommended)
- [Make](https://www.gnu.org/software/make/)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- (Optional) [LocalStack CLI](https://docs.localstack.cloud/getting-started/installation/)

---

## 🚀 Getting Started

### 1. Start LocalStack

```bash
docker-compose up
```

Ensure LocalStack is running at http://localhost:4566.

###  2. Run Full Setup

```bash
make all
```

This will:
 - Build and zip the Go Lambda
 - Create an SQS queue (todo-queue)
 - Deploy the Lambda function (my-go-lambda)
 - Map the SQS queue to trigger the Lambda
 - Manually invoke the Lambda once
 - Print setup confirmation


### 3. Send a Message to the Queue Manually

```bash
aws --endpoint-url=http://localhost:4566 sqs send-message \
--queue-url http://localhost:4566/000000000000/todo-queue \
--message-body '{"task":"buy milk"}'
```

##  📄 Output & Logs

### LocalStack Logs

In the LocalStack logs (or docker logs localstack), you should see:

```bash
📥 New Todo: buy milk
```

This means the message from SQS was correctly picked up and processed by the Lambda.

###  📤 output.json

The make invoke-lambda target manually invokes the Lambda with a fake SQS payload and writes the result to output.json.

Expected content:
```bash
"Processed SQS message(s)"
```

##  🧼 Cleanup & Utilities

Clean build artifacts:
```bash
make clean
```
Reset LocalStack state:
```bash
make reset
```
View resource status:
```bash
make status
```