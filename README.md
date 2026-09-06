# AWS Serverless Cloud Infrastructure & Security Dashboard

A serverless AWS application for tracking cloud infrastructure resources and their security review status.

The project is built with Terraform and demonstrates Infrastructure as Code (IaC), serverless application architecture, AWS service integration, REST-style API development, cloud security practices, observability, and frontend-to-cloud integration.

## Project Status

🚧 **In Development**

The serverless backend, REST-style CRUD API, CloudWatch logging, and AWS-hosted frontend are operational.

The application is deployed using a private Amazon S3 bucket with Amazon CloudFront providing HTTPS content delivery through Origin Access Control (OAC).

Current development is focused on infrastructure and security hardening, deployment validation, and final project documentation.

## Architecture

The application uses:

* **Amazon CloudFront** — Provides the public HTTPS endpoint and delivers frontend content.
* **Amazon S3** — Privately stores the dashboard HTML, CSS, and JavaScript files.
* **CloudFront Origin Access Control (OAC)** — Allows CloudFront to securely retrieve objects from the private S3 bucket.
* **Amazon API Gateway (HTTP API)** — Provides REST-style HTTP endpoints for the application.
* **AWS Lambda** — Handles API requests, validation, and application logic.
* **Amazon DynamoDB** — Stores infrastructure resource and security review data.
* **Amazon CloudWatch Logs** — Provides Lambda application and execution logging with Terraform-managed log retention.
* **AWS IAM** — Provides Lambda execution permissions and least-privilege access to AWS resources.
* **Terraform** — Provisions and manages the AWS infrastructure.
* **HTML, CSS, and JavaScript** — Provides the browser-based dashboard and communicates with the API using HTTP requests.

### Request Flow

```text
Browser
   │
   │ HTTPS
   ▼
Amazon CloudFront
   │
   │ Origin Access Control
   ▼
Private Amazon S3
   │
   ├── index.html
   ├── styles.css
   └── app.js


Browser JavaScript
   │
   │ HTTPS / JSON
   ▼
Amazon API Gateway
   │
   ▼
AWS Lambda
   │
   ├──────────────► Amazon CloudWatch Logs
   │
   ▼
Amazon DynamoDB
```

The S3 bucket blocks direct public access. Frontend objects are retrieved through CloudFront using Origin Access Control rather than exposing the bucket publicly.

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

API Gateway CORS configuration permits requests from the deployed CloudFront frontend while retaining the localhost origin for development.

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

Terraform provisions and manages:

* DynamoDB resources table
* DynamoDB secondary indexes
* Lambda function
* Lambda IAM execution role and permissions
* API Gateway HTTP API
* API Gateway routes and Lambda integration
* API Gateway CORS configuration
* Lambda invocation permissions
* CloudWatch log group and log retention
* Private S3 frontend bucket
* S3 public access controls
* S3 object ownership controls
* S3 server-side encryption
* S3 versioning
* Frontend object deployment to S3
* CloudFront distribution
* CloudFront Origin Access Control
* S3 bucket policy restricting frontend access to CloudFront

Infrastructure configuration is maintained in the `terraform/` directory.

## Security Controls

The project incorporates several cloud security practices:

* Private S3 frontend storage with public access blocked
* CloudFront Origin Access Control for authenticated access to S3
* S3 bucket policy scoped to the project's CloudFront distribution
* Read-only `s3:GetObject` permission for CloudFront
* S3 server-side encryption using AES-256
* S3 object versioning
* HTTPS delivery through CloudFront
* API Gateway CORS restrictions
* IAM-based Lambda execution permissions
* Scoped DynamoDB permissions for the Lambda function
* Environment-variable-based Lambda configuration
* CloudWatch logging with managed log retention
* Safer frontend rendering of user-controlled data using `textContent`

## Current Features

* AWS-hosted serverless web application
* Browser-based cloud resource dashboard
* Serverless CRUD API
* Create, view, update, and delete resource workflows
* DynamoDB-backed resource storage
* Request data validation
* Structured JSON API responses
* HTTP error handling
* Frontend-to-API integration using JavaScript `fetch()`
* Edit and cancel workflows
* Delete confirmation
* Loading and empty-resource states
* CloudWatch application logging
* Private S3 frontend storage
* CloudFront HTTPS content delivery
* CloudFront caching and compression
* Origin Access Control between CloudFront and S3
* Terraform-managed frontend deployment
* Terraform-managed AWS infrastructure

## Planned Development

Next development milestones include:

* Infrastructure and IAM security review and hardening
* Full infrastructure destroy/redeploy validation
* Final architecture diagram
* Project screenshots
* Final project documentation

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
│   ├── cloudfront.tf
│   ├── cloudwatch.tf
│   ├── dynamodb.tf
│   ├── iam.tf
│   ├── lambda.tf
│   ├── locals.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── s3.tf
├── .gitignore
└── README.md
```

## Development Progress

### Completed

* Terraform AWS provider configuration
* DynamoDB table and secondary indexes
* Lambda execution role and DynamoDB permissions
* Lambda CRUD application logic
* Request validation and HTTP response handling
* API Gateway HTTP API and CRUD routes
* Lambda and API Gateway integration
* CloudWatch application logging and log retention
* Browser-based frontend
* Frontend CRUD integration
* API Gateway CORS configuration
* Frontend edit, cancel, and delete confirmation workflows
* Safer rendering of resource data in the browser
* Private S3 frontend storage
* S3 encryption and versioning
* Terraform-managed frontend object deployment
* CloudFront distribution
* CloudFront Origin Access Control
* CloudFront-restricted S3 bucket policy
* HTTPS frontend delivery
* Production frontend-to-API CORS integration

### In Progress

* Infrastructure security hardening
* Full destroy/redeploy validation
* Final architecture diagram
* Screenshots and final project documentation
