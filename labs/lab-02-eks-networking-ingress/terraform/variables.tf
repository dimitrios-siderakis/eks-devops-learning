variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "lab01-eks"
}

# Pull these from lab-01 outputs
variable "oidc_provider_arn" {
  description = "OIDC provider ARN from lab-01 Terraform output"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL (without https://) from lab-01 Terraform output"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from lab-01 Terraform output"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for ExternalDNS"
  type        = string
}
