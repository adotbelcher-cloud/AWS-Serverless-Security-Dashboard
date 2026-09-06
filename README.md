# AWS Serverless Cloud Infrastructure & Security Dashboard

A serverless AWS application for tracking cloud infrastructure resources and their security review status.

The project is built with Terraform and demonstrates Infrastructure as Code (IaC), serverless application architecture, AWS service integration, REST-style API development, cloud security practices, observability, and frontend-to-cloud integration.

## Project Status

🚧 **In Development**

The serverless backend, REST-style CRUD API, CloudWatch logging, and local frontend are operational.

Current development is focused on deploying the frontend to AWS, infrastructure and security hardening, and final project documentation.

## Architecture

The current architecture uses:

* **Amazon API Gateway (HTTP API)** — Provides HTTP endpoints for the application.
* **AWS Lambda** — Handles API requests, validation, and application logic.
* **Amazon DynamoDB** — Stores infrastructure resource and security review data.
* **Amazon CloudWatch Logs** — Provides application and Lambda execution logging with Terraform-managed log retention.
* **AWS IAM** — Provides Lambda execution permissions and access to DynamoDB.
* **Terraform** — Provisions and manages AWS infrastructure.
* **HTML, CSS, and JavaScript** — Provides the browser-based dashboard and communicates with the API using HTTP requests.

Current request flow:

```text
Browser
   │
   │  HTTP requests
   ▼
API Gateway
   │
   ▼
AWS Lambda
   │
   ├──────────────► CloudWatch Logs
   │
   ▼
Amazon DynamoDB
```

The frontend currently runs locally during development. Static hosting with Amazon S3 and CloudFront is planned.

## API

The application supports the following endpoints:

| Method   | Endpoint          | Description                    |
| -------- | ----------------- | ------------------------------ |
| `GET`    | `/resources`      | Retrieve all tracked resources |
| `GET`    | `/resources/{id}` | Retrieve a specific resource   |
| `POST`   | `/resources`      | Create a new resource          |
| `PATCH`  | `/resources/{id}` | Update an existing resource    |
| `DELETE` | `/resources/{id}` | Delete a resource              |

API responses use JSON with appropriate HTTP status codes and validation for malformed or invalid request bodies.

API Gateway CORS configuration allows the local development frontend to communicate with the API from the browser.

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
* API Gateway CORS configuration
* Lambda invocation permissions
* CloudWatch log group and log retention

Infrastructure configuration is maintained in the `terraform/` directory.

## Current Features

* Serverless CRUD API
* Browser-based resource dashboard
* Create, view, update, and delete resource workflows
* DynamoDB-backed resource storage
* Request data validation
* Structured JSON API responses
* HTTP error handling
* Frontend-to-API integration using JavaScript `fetch()`
* CORS configuration for local frontend development
* Edit and cancel workflows
* Delete confirmation
* Loading and empty-resource states
* Safer frontend rendering of user-controlled data using `textContent`
* CloudWatch application logging
* Terraform-managed CloudWatch log retention
* Terraform-managed AWS infrastructure
* IAM-based Lambda permissions
* Environment-variable-based Lambda configuration

## Planned Development

Next development milestones include:

* Private static frontend hosting with Amazon S3
* Amazon CloudFront distribution
* CloudFront Origin Access Control (OAC) for private S3 access
* Production CORS configuration for the deployed frontend
* Infrastructure and IAM security review and hardening
* Full infrastructure destroy/redeploy validation
* Architecture diagram
* Project screenshots and final documentation

## Repository Structure

```text
aws-serverless-security-dashboard/
├── frontend/
│   ├── app.js
│   ├── index.html
│   └── styles.css
├── lambda/
│   └── lambda_function.py
├── terraform/
│   ├── api_gateway.tf
│   ├── cloudwatch.tf
│   ├── dynamodb.tf
│   ├── iam.tf
│   ├── lambda.tf
│   ├── locals.tf
│   ├── outputs.tf
│   └── providers.tf
├── .gitignore
└── README.md
```

## Development Progress

Completed:

* Terraform AWS provider configuration
* DynamoDB table and secondary indexes
* Lambda execution role and DynamoDB permissions
* Lambda CRUD application logic
* Request validation and HTTP response handling
* API Gateway HTTP API and CRUD routes
* Lambda and API Gateway integration
* CloudWatch application logging and log retention
* Local browser frontend
* Frontend CRUD integration
* API Gateway CORS configuration
* Frontend edit, cancel, and delete confirmation workflows
* Safer rendering of resource data in the browser

In progress:

* AWS frontend hosting
* Infrastructure security hardening
* Deployment validation
* Final architecture and project documentation
