variable "aws_region" {
  description = "AWS region where the EKS cluster is deployed."
  type        = string
}

variable "eks_cluster_name" {
  description = "Existing EKS cluster used for generated APIs."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service."
  type        = string
  default     = "default"
}

variable "service_name" {
  description = "Name used by Kubernetes resources and the ingress path prefix."
  type        = string
  default     = "${{ values.name }}"
}

variable "container_image" {
  description = "Container image published by the service repository."
  type        = string
  default     = "REPLACE_WITH_CONTAINER_IMAGE"
}

variable "container_port" {
  description = "Port exposed by the service container."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP endpoint used by the ALB and readiness probe."
  type        = string
  default     = "/api/v1/items"
}

variable "ingress_host" {
  description = "Optional host for the public ALB ingress."
  type        = string
  default     = ""
}

variable "replicas" {
  description = "Number of service replicas."
  type        = number
  default     = 2
}

variable "environment" {
  description = "Environment variables passed to the container."
  type        = map(string)
  default     = {}
}