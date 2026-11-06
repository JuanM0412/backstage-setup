output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backstage.repository_url
}

output "rds_endpoint" {
  value = module.rds.db_instance_address
}
