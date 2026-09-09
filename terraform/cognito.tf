# This file defines the AWS Cognito resources for the serverless security dashboard.

# Creates a Cognito user pool for the serverless security dashboard, allowing users to sign up and log in using their email addresses. Configures password policies and email verification.
resource "aws_cognito_user_pool" "dashboard" {
  name = "serverless-security-dashboard-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  tags = merge(local.common_tags, {
    Name = "serverless-security-dashboard-users"
  })

}

# Creates a Cognito user pool client for the serverless security dashboard, allowing the frontend to authenticate users and obtain JWT tokens. Configures authentication flows and prevents user existence errors.
resource "aws_cognito_user_pool_client" "dashboard" {
  name         = "serverless-security-dashboard-client"
  user_pool_id = aws_cognito_user_pool.dashboard.id

  generate_secret               = false
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_flows = [
    "code"
  ]

  allowed_oauth_scopes = [
    "openid",
    "email"
  ]

  callback_urls = [
    "https://${aws_cloudfront_distribution.frontend.domain_name}"
  ]

  logout_urls = [
    "https://${aws_cloudfront_distribution.frontend.domain_name}"
  ]

  supported_identity_providers = [
    "COGNITO"
  ]
}

# Creates a Cognito user pool domain for the serverless security dashboard, allowing users to access the login and signup pages. Configures the domain name and associates it with the user pool.
resource "aws_cognito_user_pool_domain" "dashboard" {
  domain       = "serverless-security-dashboard"
  user_pool_id = aws_cognito_user_pool.dashboard.id
}