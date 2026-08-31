# Stores cloud infrastructure resources and their security review information.

resource "aws_dynamodb_table" "resources" {
  name         = "serverless-security-dashboard-resources"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "environment"
    type = "S"
  }

  attribute {
    name = "owner"
    type = "S"
  }

  attribute {
    name = "securityReview"
    type = "S"
  }

  # global_secondary_index allows for efficient querying of resources based on specific attributes.

  global_secondary_index {
    name = "EnvironmentIndex"

    key_schema {
      attribute_name = "environment"
      key_type       = "HASH"
    }

    projection_type = "ALL"
  }

  global_secondary_index {
    name = "OwnerIndex"

    key_schema {
      attribute_name = "owner"
      key_type       = "HASH"
    }

    projection_type = "ALL"
  }


  global_secondary_index {
    name = "SecurityReviewIndex"

    key_schema {
      attribute_name = "securityReview"
      key_type       = "HASH"
    }

    projection_type = "ALL"
  }

  # Identifies the resource for organization and infrastructure management.
  tags = {
    Name        = "serverless-security-dashboard-resources"
    Project     = "AWS Serverless Security Dashboard"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}

