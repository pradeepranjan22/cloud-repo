output "cluster_id" {
  value = aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
  description = "OIDC provider ARN for IRSA"
}

output "node_group_names" {
  value = [for ng in aws_eks_node_group.this : ng.node_group_name]
}

output "node_group_arns" {
  value = { for k, ng in aws_eks_node_group.this : k => ng.arn }
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}