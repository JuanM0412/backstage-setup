variable "aws_region" {
  description = "AWS region where the Lambda and API Gateway are deployed."
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the existing API Gateway REST API."
  type        = string
}

variable "service_name" {
  description = "Service name used as the Lambda and API Gateway path prefix."
  type        = string
  default     = "${{ values.name }}"
}

variable "source_dir" {
  description = "Directory containing the Lambda source package."
  type        = string
  default     = "../src"
}

variable "lambda_runtime" {
  description = "AWS Lambda runtime."
  type        = string
{% if values.language == 'python' %}
  default     = "python3.12"
{% else %}
  default     = "nodejs22.x"
{% endif %}
}

variable "lambda_handler" {
  description = "Lambda handler in module.function format."
  type        = string
  default     = "lambda.handler"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory allocation in MB."
  type        = number
  default     = 512
}

variable "environment" {
  description = "Environment variables passed to the Lambda."
  type        = map(string)
  default     = {}
}