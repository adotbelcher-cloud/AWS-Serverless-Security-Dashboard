# Packages the Lambda source code into a ZIP file for deployment.

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Creates the Lambda function that handles API requests for the security dashboard.
# Configures the Lambda execution role, Python handler, and runtime.
# Deploys the packaged Lambda code and detects source code changes.
# Provides the DynamoDB table name to the Lambda function at runtime.

resource "aws_lambda_function" "api" {
  function_name = "serverless-security-dashboard-api"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.14"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.resources.name
    }
  }

  tags = merge(local.common_tags,
    {
      Name = "serverless-security-dashboard-lambda-api"
    }
  )
}