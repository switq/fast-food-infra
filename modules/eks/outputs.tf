output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.fast_food_cluster.id
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.fast_food_cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.fast_food_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group do cluster EKS"
  value       = aws_eks_cluster.fast_food_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Certificado de autoridade do cluster"
  value       = aws_eks_cluster.fast_food_cluster.certificate_authority[0].data
}

output "node_group_arn" {
  description = "ARN do node group"
  value       = aws_eks_node_group.fast_food_nodes.arn
}

output "node_group_status" {
  description = "Status do node group"
  value       = aws_eks_node_group.fast_food_nodes.status
}
