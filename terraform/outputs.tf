# Displays the base URL for the HTTP API after deployment.
output "api_base_url" {
  value       = aws_apigatewayv2_api.api.api_endpoint
  description = "Base URL for the serverless security dashboard HTTP API."
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.frontend.domain_name
  description = "CloudFront domain name for the dashboard frontend"
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID for dashboard authentication"
  value       = aws_cognito_user_pool.dashboard.id
}

output "cognito_client_id" {
  description = "Cognito app client ID for dashboard authentication"
  value       = aws_cognito_user_pool_client.dashboard.id
}

output "cognito_domain" {
  description = "Cognito domain used for dashboard authentication"
  value       = aws_cognito_user_pool_domain.dashboard.domain
}