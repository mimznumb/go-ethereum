output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}


output "node_role_arn" {
  value = module.eks.node_iam_role_arn
}

output "irsa_role_arn" {
  value       = try(aws_iam_role.irsa_role[0].arn, null)
  description = "IAM role ARN for the IRSA service account (if enabled)"
}
