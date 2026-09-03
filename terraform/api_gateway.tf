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

# Creates one API Gateway route per entry in local.api_routes (see locals.tf),
# all pointed at the same Lambda integration.
resource "aws_apigatewayv2_route" "routes" {
  for_each = local.api_routes

  api_id    = aws_apigatewayv2_api.api.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

moved {
  from = aws_apigatewayv2_route.get_resources_route
  to   = aws_apigatewayv2_route.routes["GET /resources"]
}

moved {
  from = aws_apigatewayv2_route.get_resource_by_id_route
  to   = aws_apigatewayv2_route.routes["GET /resources/{id}"]
}

moved {
  from = aws_apigatewayv2_route.post_resource_route
  to   = aws_apigatewayv2_route.routes["POST /resources"]
}

moved {
  from = aws_apigatewayv2_route.patch_resource_by_id_route
  to   = aws_apigatewayv2_route.routes["PATCH /resources/{id}"]
}

moved {
  from = aws_apigatewayv2_route.delete_resource_by_id_route
  to   = aws_apigatewayv2_route.routes["DELETE /resources/{id}"]
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