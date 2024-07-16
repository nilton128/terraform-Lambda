provider "aws" {
  region = "us-east-1" # Substitua pela sua região
}

# Data source to create ZIP file from the lambda_function.py
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# Criação da função Lambda
resource "aws_lambda_function" "stop_ec2_instance" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "StopEC2Instance"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  runtime          = "python3.8"
  timeout          = 30
}

# Política IAM para a função Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:StopInstances"
        ],
        "Resource" : [
          "arn:aws:ec2:us-east-1:CONTA-AWS:instance/i-ID" // Substitua pela sua instância
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}


# EventBridge Rule
resource "aws_cloudwatch_event_rule" "stop_ec2_schedule" {
  name                = "StopEC2InstanceSchedule"
  description         = "Disparar função Lambda para desligar EC2 diariamente às 19h"
  schedule_expression = "cron(20 19 * * ? *)"
}

# Permissão para o EventBridge invocar a função Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2_schedule.arn
}

# Associação da regra do EventBridge com a função Lambda
resource "aws_cloudwatch_event_target" "stop_ec2_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_schedule.name
  target_id = "StopEC2InstanceFunction"
  arn       = aws_lambda_function.stop_ec2_instance.arn
}
