terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-learning"
      Lab         = "lab-02-eks-networking-ingress"
      ManagedBy   = "terraform"
      Environment = "lab"
    }
  }
}
