provider "aws" {
  #access_key = var.aws_access_key_id
  #secret_key = var.aws_secret_access_key
  #region     = var.aws_region
}

resource "aws_sqs_queue" "my_queue" {
  name                      = "Pedidos"
  message_retention_seconds = 60

  tags = {
    Environment = "dev"
    Project     = "sqs-example"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "LambdaSQSdynamoDBRolePedidosRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_sqs_execution_10" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_execution_11" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

# Package the Lambda function code
data "archive_file" "example" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda/function.zip"
}


# Lambda function
resource "aws_lambda_function" "example" {
  filename         = data.archive_file.example.output_path
  function_name    = "inventario"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  #source_code_hash = data.archive_file.example.output_base64sha256

  runtime = "nodejs16.x"

  environment {
    variables = {
      #ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }

  architectures = ["x86_64"] # Graviton support for better price/performance
}

resource "aws_iam_policy" "custom_lambda_logs" {
  name        = "CustomLambdaLogPolicy"
  description = "Custom policy for specific CloudWatch Logs access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:us-east-1:332802448540:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:us-east-1:332802448540:log-group:/aws/lambda/inventario:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_custom_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.custom_lambda_logs.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.my_queue.arn
  function_name    = aws_lambda_function.example.arn
  batch_size       = 10
  enabled          = true
}
