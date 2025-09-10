# provider "aws" {
#   region = "eu-north-1" 
# }

provider "aws" {
  region = var.aws_region
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_secretsmanager_secret" "slack_webhook" {
  name        = "slack-webhook"
  description = "Slack Incoming Webhook URL"
}

resource "aws_secretsmanager_secret_version" "slack_webhook_value" {
  secret_id     = aws_secretsmanager_secret.slack_webhook.id
  secret_string = var.slack_webhook_url
}

resource "aws_lambda_function" "slack_alert" {
  function_name = "iot-slack-alert"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

#   environment {
#     variables = {
#       SECRET_NAME = aws_secretsmanager_secret.slack_webhook.name
#       REGION      = "us-north-1"
#     }
#   }

    environment {
        variables = {
        SECRET_NAME = aws_secretsmanager_secret.slack_webhook.name
        REGION      = var.aws_region
      }
  }

}

resource "aws_iot_topic_rule" "iot_to_lambda" {
  name        = "IoTToSlackRule"
  description = "Route IoT alerts to Slack via Lambda"
  enabled     = true
  sql         = "SELECT * FROM 'sensors/alerts'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.slack_alert.arn
  }
}

resource "aws_lambda_permission" "allow_iot" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.iot_to_lambda.arn
}

variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL"
  type        = string
  sensitive   = true
}


variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}
