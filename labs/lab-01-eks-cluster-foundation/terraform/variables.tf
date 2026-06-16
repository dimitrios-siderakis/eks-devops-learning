variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "lab01-eks"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to deploy into (minimum 3 for production)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["m6i.large"]
}

variable "node_group_desired" {
  description = "Desired node count"
  type        = number
  default     = 3
}

variable "node_group_min" {
  description = "Minimum node count"
  type        = number
  default     = 2
}

variable "node_group_max" {
  description = "Maximum node count"
  type        = number
  default     = 6
}
