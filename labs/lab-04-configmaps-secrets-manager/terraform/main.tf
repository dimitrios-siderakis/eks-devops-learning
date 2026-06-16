terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "devops-learning"
      Lab       = "lab-04-configmaps-secrets"
      ManagedBy = "terraform"
    }
  }
}

variable "aws_region"       { type = string; default = "us-east-1" }
variable "cluster_name"     { type = string; default = "lab01-eks" }
variable "oidc_provider_arn" { type = string; description = "From lab-01 output: oidc_provider_arn" }
variable "oidc_provider_url" { type = string; description = "From lab-01 output: oidc_provider_url" }

##############################################################################
# AWS Secrets Manager — two secrets for the lab
##############################################################################

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "lab04/db-password"
  description             = "Lab 04 database password"
  recovery_window_in_days = 0   # immediate delete for lab teardown
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "InitialPassword123!"
}

resource "aws_secretsmanager_secret" "db_username" {
  name                    = "lab04/db-username"
  description             = "Lab 04 database username"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_username" {
  secret_id     = aws_secretsmanager_secret.db_username.id
  secret_string = "appuser"
}

##############################################################################
# IRSA role for the Secrets Store CSI Driver pod
##############################################################################

data "aws_iam_policy_document" "csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:config-lab:csi-app-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "csi_app" {
  name               = "${var.cluster_name}-lab04-csi-app"
  assume_role_policy = data.aws_iam_policy_document.csi_assume.json
}

data "aws_iam_policy_document" "csi_secrets" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      aws_secretsmanager_secret.db_password.arn,
      aws_secretsmanager_secret.db_username.arn,
    ]
  }
}

resource "aws_iam_policy" "csi_secrets" {
  name   = "${var.cluster_name}-lab04-csi-secrets"
  policy = data.aws_iam_policy_document.csi_secrets.json
}

resource "aws_iam_role_policy_attachment" "csi_secrets" {
  role       = aws_iam_role.csi_app.name
  policy_arn = aws_iam_policy.csi_secrets.arn
}

##############################################################################
# Outputs
##############################################################################

output "csi_irsa_role_arn" {
  value = aws_iam_role.csi_app.arn
}

output "secrets_manager_db_password_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}

output "aws_region" {
  value = var.aws_region
}
