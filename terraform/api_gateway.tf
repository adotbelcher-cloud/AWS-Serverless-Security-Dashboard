# Creates the HTTP API that exposes the security dashboard backend.
resource "aws_apigatewayv2_api" "api" {
  name          = "serverless-security-dashboard-api"
  protocol_type = "HTTP"

  tags = merge(
    local.common_tags,
    {
      Name = "serverless-security-dashboard-api"
    }
  )
}

# Connects the HTTP API to the Lambda function.
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Routes GET /resources requests to the Lambda integration.
resource "aws_apigatewayv2_route" "get_resources_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /resources"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
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