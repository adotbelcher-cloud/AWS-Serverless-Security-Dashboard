
# Common tags applied to AWS resources throughout the project.

locals {
  common_tags = {
    Project     = "AWS Serverless Security Dashboard"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}