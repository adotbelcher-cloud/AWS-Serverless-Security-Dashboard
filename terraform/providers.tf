# Defines the Terraform providers required to provision and package AWS resources.
# Provides the resources needed to create and manage AWS infrastructure.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60"
    }

    # Packages the Lambda source code into a ZIP file for deployment.

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.3"
    }
  }
}

# Configures the AWS provider to deploy resources in the US East (N. Virginia) Region.

provider "aws" {
  region = "us-east-1"
}
