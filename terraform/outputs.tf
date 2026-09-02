# Displays the base URL for the HTTP API after deployment.
output "api_base_url" {
  value       = aws_apigatewayv2_api.api.api_endpoint
  description = "Base URL for the serverless security dashboard HTTP API."
}