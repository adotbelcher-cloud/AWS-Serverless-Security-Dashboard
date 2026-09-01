# IAM role that allows the Lambda function to assume an AWS execution identity.
resource "aws_iam_role" "lambda_execution" {
  name = "serverless-security-dashboard-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(local.common_tags,
    {
      Name = "serverless-security-dashboard-lambda-execution-role"
    }
  )

}

# Allows the Lambda function to write execution logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# List what actions the Lambda function can perform on DynamoDB resources for the serverless security dashboard.
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "serverless-security-dashboard-dynamodb-access-policy"
  description = "Policy granting access to DynamoDB resources for the serverless security dashboard."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = [aws_dynamodb_table.resources.arn, "${aws_dynamodb_table.resources.arn}/index/*"]
      }
    ]
  })

  tags = merge(local.common_tags,
    {
      Name = "serverless-security-dashboard-dynamodb-access-policy"
    }
  )
}

# Allows the Lambda function to access DynamoDB resources for the serverless security dashboard.
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}