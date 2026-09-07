# This file contains the Terraform configuration for the private S3 bucket
# that stores the dashboard frontend files served through CloudFront.

# S3 Bucket 
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = local.frontend_bucket_name
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = local.frontend_bucket_name
  })
}

# S3 Bucket Public Access Block to restrict public access
resource "aws_s3_bucket_public_access_block" "frontend_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Ownership Controls to enforce bucket owner ownership
resource "aws_s3_bucket_ownership_controls" "frontend_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# AES-256 Server-Side Encryption Configuration for the S3 Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning to enable versioning for the S3 Bucket
resource "aws_s3_bucket_versioning" "frontend_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Uploads the dashboard HTML file to S3.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../frontend/index.html")
}

# Uploads the dashboard stylesheet to S3.
resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "styles.css"
  source       = "${path.module}/../frontend/styles.css"
  content_type = "text/css"
  etag         = filemd5("${path.module}/../frontend/styles.css")
}

# Uploads the dashboard JavaScript file to S3.
resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "app.js"
  source       = "${path.module}/../frontend/app.js"
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/../frontend/app.js")
}

# Generates the dashboard deployment configuration from Terraform-managed AWS resources.
resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "config.js"
  content_type = "application/javascript"

  content = <<-EOT
    window.APP_CONFIG = ${jsonencode({
  apiBaseUrl      = aws_apigatewayv2_api.api.api_endpoint
  cognitoClientId = aws_cognito_user_pool_client.dashboard.id
  cognitoDomain   = "${aws_cognito_user_pool_domain.dashboard.domain}.auth.us-east-1.amazoncognito.com"
  redirectUri     = "https://${aws_cloudfront_distribution.frontend.domain_name}"
})};
  EOT
}