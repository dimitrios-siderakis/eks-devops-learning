terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }

  # Uncomment for real use — use S3 backend with state locking
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "eks/lab01/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-learning"
      Lab         = "lab-01-eks-foundation"
      ManagedBy   = "terraform"
      Environment = "lab"
    }
  }
}
