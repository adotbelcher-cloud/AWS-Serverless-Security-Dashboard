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
# Defines each API route and whether Cognito authentication is required.

locals {
  api_routes = {
    "GET /resources" = {
      authorization_type = "NONE"
    }

    "GET /resources/{id}" = {
      authorization_type = "NONE"
    }

    "POST /resources" = {
      authorization_type = "JWT"
    }

    "PATCH /resources/{id}" = {
      authorization_type = "JWT"
    }

    "DELETE /resources/{id}" = {
      authorization_type = "JWT"
    }
  }
}

locals {
  # The name of the S3 bucket used to host the frontend of the security dashboard.
  frontend_bucket_name = "aws-serverless-security-dashboard-frontend"
}
