variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "backstage"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "database_name" {
  type    = string
  default = "backstage"
}

variable "database_username" {
  type      = string
  sensitive = true
  default   = "backstage"
}
