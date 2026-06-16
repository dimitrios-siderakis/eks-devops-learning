##############################################################################
# Lab 06 Terraform — Fluent Bit IRSA Role
#
# Provisions the IAM role that the Fluent Bit sidecar needs to write to
# CloudWatch Logs. The role ARN is then annotated on the ServiceAccount.
#
# Inputs: oidc_provider_arn and oidc_provider_url from lab-01 outputs
##############################################################################

variable "cluster_name" {
  type    = string
  default = "lab01-eks"
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from lab-01 outputs"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from lab-01 outputs (without https://)"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

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
}

##############################################################################
# Fluent Bit IRSA role — scoped to the fluent-bit-sa ServiceAccount
# in the init-lab namespace only
##############################################################################
resource "aws_iam_role" "fluent_bit" {
  name = "${var.cluster_name}-fluent-bit-init-lab"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:init-lab:fluent-bit-sa"
        }
      }
    }]
  })

  tags = { Lab = "lab-06" }
}

resource "aws_iam_role_policy" "fluent_bit_cloudwatch" {
  name = "FluentBitCloudWatchPolicy"
  role = aws_iam_role.fluent_bit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Scoped to the /eks/init-lab/ log group prefix only
        Sid    = "AllowLogStreamOperations"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/eks/init-lab/*:*"
      },
      {
        Sid      = "AllowCreateLogGroup"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/eks/init-lab/*"
      },
    ]
  })
}

##############################################################################
# CloudWatch Log Group — pre-create so retention is set immediately
##############################################################################
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/eks/init-lab/app"
  retention_in_days = 7   # lab environment — keep short

  tags = { Lab = "lab-06" }
}

##############################################################################
# Outputs — used to annotate the ServiceAccount after apply
##############################################################################
output "fluent_bit_role_arn" {
  value = aws_iam_role.fluent_bit.arn
}

output "annotate_command" {
  value = "kubectl annotate sa fluent-bit-sa -n init-lab eks.amazonaws.com/role-arn=${aws_iam_role.fluent_bit.arn} --overwrite"
}
