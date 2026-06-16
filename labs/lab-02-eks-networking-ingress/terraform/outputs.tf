output "lbc_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.lbc.arn
}

output "externaldns_role_arn" {
  description = "IRSA role ARN for ExternalDNS"
  value       = aws_iam_role.externaldns.arn
}

output "vpc_id" {
  description = "VPC ID (pass-through for helm install command)"
  value       = var.vpc_id
}
