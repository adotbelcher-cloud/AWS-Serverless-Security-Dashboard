# AWS Serverless Cloud Infrastructure & Security Dashboard

A serverless AWS application for tracking cloud infrastructure resources and their security review status.

The project is built with Terraform and demonstrates Infrastructure as Code, serverless application architecture, AWS service integration, API development, and cloud security practices.

## Project Status

🚧 **In Development**

The serverless backend and REST-style CRUD API are operational. Current development is focused on observability, frontend development, and infrastructure/security hardening.

## Architecture

The current backend architecture uses:

* **Amazon API Gateway (HTTP API)** — Provides HTTP endpoints for the application.
* **AWS Lambda** — Handles API requests, validation, and application logic.
* **Amazon DynamoDB** — Stores infrastructure resource and security review data.
* **AWS IAM** — Provides permissions for Lambda execution and access to DynamoDB.
* **Terraform** — Provisions and manages AWS infrastructure.

Current request flow:

```text
Client
  │
  ▼
API Gateway
  │
  ▼
AWS Lambda
  │
  ▼
Amazon DynamoDB
```

## API

The application currently supports the following endpoints:

| Method   | Endpoint          | Description                    |
| -------- | ----------------- | ------------------------------ |
| `GET`    | `/resources`      | Retrieve all tracked resources |
| `GET`    | `/resources/{id}` | Retrieve a specific resource   |
| `POST`   | `/resources`      | Create a new resource          |
| `PATCH`  | `/resources/{id}` | Update an existing resource    |
| `DELETE` | `/resources/{id}` | Delete a resource              |

API responses use JSON with appropriate HTTP status codes and validation for malformed or invalid request bodies.

## Resource Data Model

Each tracked resource contains:

* `id`
* `name`
* `type`
* `environment`
* `owner`
* `status`
* `securityReview`
* `notes`
* `createdAt`
* `updatedAt`

Supported environments:

* `development`
* `staging`
* `production`

Supported resource statuses:

* `active`
* `inactive`
* `decommissioned`

Supported security review statuses:

* `pending`
* `in-progress`
* `complete`

## Infrastructure as Code

Terraform currently provisions and manages:

* DynamoDB resources table
* DynamoDB secondary indexes
* Lambda function
* Lambda IAM execution role and permissions
* API Gateway HTTP API
* API Gateway routes and Lambda integration
* Lambda invocation permissions

Infrastructure configuration is maintained in the `terraform/` directory.

## Current Features

* Serverless CRUD API
* DynamoDB-backed resource storage
* Request data validation
* Structured JSON API responses
* HTTP error handling
* Terraform-managed AWS infrastructure
* IAM-based Lambda permissions
* Environment-variable-based application configuration

## Planned Development

Next development milestones include:

* CloudWatch logging and observability improvements
* Frontend security dashboard
* Frontend-to-API integration
* CORS configuration
* Static frontend hosting with Amazon S3 and CloudFront
* Infrastructure and IAM security hardening
* Architecture diagram and project documentation
* Full infrastructure destroy/redeploy validation

## Repository Structure

```text
aws-serverless-security-dashboard/
├── lambda/
│   └── lambda_function.py
├── terraform/
│   ├── api_gateway.tf
│   ├── dynamodb.tf
│   ├── iam.tf
│   ├── lambda.tf
│   ├── locals.tf
│   ├── outputs.tf
│   └── providers.tf
├── .gitignore
└── README.md
```
