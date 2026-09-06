# Common tags applied to AWS resources throughout the project.
locals {
  common_tags = {
    Project     = "AWS Serverless Security Dashboard"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}

# Route keys (method + path) for the security dashboard's HTTP API.
# Used by aws_apigatewayv2_route.routes in api_gateway.tf to create one route per entry.
locals {
  api_routes = toset([
    "GET /resources",
    "GET /resources/{id}",
    "POST /resources",
    "PATCH /resources/{id}",
    "DELETE /resources/{id}",
  ])
}

locals {
  # The name of the S3 bucket used to host the frontend of the security dashboard.
  frontend_bucket_name = "aws-serverless-security-dashboard-frontend"
}
