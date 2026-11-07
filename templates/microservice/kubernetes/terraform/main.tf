terraform {
  required_version = ">= 1.6.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "backend_apis" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "backend_apis" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.backend_apis.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.backend_apis.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.backend_apis.token
}

resource "kubernetes_deployment_v1" "service" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
    labels = {
      app = var.service_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.service_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.service_name
        }
      }

      spec {
        image_pull_secrets {
          name = "ghcr-pull"
        }

        container {
          name              = var.service_name
          image             = var.container_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = var.container_port
          }

          dynamic "env" {
            for_each = var.environment
            content {
              name  = env.key
              value = env.value
            }
          }

          readiness_probe {
            http_get {
              path = var.health_check_path
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "service" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.service_name
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "service" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = var.health_check_path
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/${var.service_name}/*"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = kubernetes_service_v1.service.metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}