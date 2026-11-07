terraform {
  required_version = ">= 1.6.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "time_sleep" "api_gateway_propagation" {
  depends_on      = [aws_api_gateway_integration.service, aws_api_gateway_integration.proxy]
  create_duration = "10s"
}

data "aws_api_gateway_rest_api" "backend" {
  name = var.api_gateway_name
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.service_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "/tmp/${var.service_name}.zip"
}

resource "aws_lambda_function" "service" {
  function_name    = var.service_name
  role             = aws_iam_role.lambda.arn
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = var.environment
  }

  depends_on = [aws_iam_role_policy_attachment.basic_execution]
}

resource "aws_api_gateway_resource" "service" {
  rest_api_id = data.aws_api_gateway_rest_api.backend.id
  parent_id   = data.aws_api_gateway_rest_api.backend.root_resource_id
  path_part   = var.service_name
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = data.aws_api_gateway_rest_api.backend.id
  parent_id   = aws_api_gateway_resource.service.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "service" {
  rest_api_id   = data.aws_api_gateway_rest_api.backend.id
  resource_id   = aws_api_gateway_resource.service.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = data.aws_api_gateway_rest_api.backend.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "service" {
  rest_api_id             = data.aws_api_gateway_rest_api.backend.id
  resource_id             = aws_api_gateway_resource.service.id
  http_method             = aws_api_gateway_method.service.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.service.invoke_arn
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = data.aws_api_gateway_rest_api.backend.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.service.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_api_gateway_rest_api.backend.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "service" {
  rest_api_id = data.aws_api_gateway_rest_api.backend.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.service.id,
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.service.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.service.id,
      aws_api_gateway_integration.proxy.id,
      aws_lambda_function.service.source_code_hash,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.service,
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.service,
    aws_api_gateway_integration.proxy,
    aws_lambda_permission.api_gateway,
    time_sleep.api_gateway_propagation,
  ]
}

output "api_gateway_id" {
  description = "ID of the shared API Gateway REST API."
  value       = data.aws_api_gateway_rest_api.backend.id
}

output "api_gateway_deployment_id" {
  description = "Deployment ID to associate with the shared prod stage."
  value       = aws_api_gateway_deployment.service.id
}