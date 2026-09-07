# Creates the HTTP API that exposes the security dashboard backend.
resource "aws_apigatewayv2_api" "api" {
  name          = "serverless-security-dashboard-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "http://localhost:8000",
      "https://${aws_cloudfront_distribution.frontend.domain_name}",
    ]

    allow_methods = ["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = [
      "content-type",
      "authorization",
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "serverless-security-dashboard-api"
    }
  )
}

# Creates a Cognito authorizer for the HTTP API, allowing JWT-based authentication.
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.api.id
  name             = "serverless-security-dashboard-cognito-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://${aws_cognito_user_pool.dashboard.endpoint}"
    audience = [aws_cognito_user_pool_client.dashboard.id]
  }
}

# Connects the HTTP API to the Lambda function.
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Creates one API Gateway route per entry in local.api_routes (see locals.tf),
# all pointed at the same Lambda integration.
resource "aws_apigatewayv2_route" "routes" {
  for_each = local.api_routes

  api_id    = aws_apigatewayv2_api.api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  authorization_type = each.value.authorization_type
  authorizer_id      = each.value.authorization_type == "JWT" ? aws_apigatewayv2_authorizer.cognito.id : null
}

# Deploys the HTTP API using the default stage.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Allows API Gateway to invoke the Lambda function.
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}