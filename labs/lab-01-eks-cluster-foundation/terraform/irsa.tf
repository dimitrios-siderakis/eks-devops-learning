##############################################################################
# IRSA — IAM Roles for Service Accounts
#
# Pattern: one IAM role per SA, trust policy scoped to exact SA name + namespace.
# This module creates a test role with S3 read-only for lab validation.
# Replicate this pattern for every workload that needs AWS access.
##############################################################################

locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.this.arn
  # Strip https:// from issuer URL for IAM policy conditions
  oidc_provider_id  = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

##############################################################################
# Test IRSA role — used by irsa-test-pod.yaml to verify IRSA works
##############################################################################

data "aws_iam_policy_document" "irsa_test_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:default:irsa-test-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa_test" {
  name               = "${var.cluster_name}-irsa-test"
  assume_role_policy = data.aws_iam_policy_document.irsa_test_assume.json
}

# Read-only S3 — minimal permissions for test validation
resource "aws_iam_role_policy_attachment" "irsa_test_s3" {
  role       = aws_iam_role.irsa_test.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

##############################################################################
# EBS CSI Driver IRSA role (required for aws-ebs-csi-driver add-on)
##############################################################################

data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
