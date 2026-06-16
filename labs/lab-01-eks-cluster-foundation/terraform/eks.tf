##############################################################################
# EKS Cluster
# - Private + public endpoint (public restricted to your IP in production)
# - All control plane log types enabled
# - Secrets envelope encryption via KMS
##############################################################################

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks" {
  description             = "EKS secrets envelope encryption — ${var.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    # In production, restrict to your corporate CIDR:
    # public_access_cidrs = ["203.0.113.0/24"]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

##############################################################################
# OIDC Provider — required for IRSA
##############################################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

##############################################################################
# Managed Node Group — Bottlerocket, private subnets only
##############################################################################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = var.node_instance_types
  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_group_desired
    min_size     = var.node_group_min
    max_size     = var.node_group_max
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  # Drain nodes gracefully during updates
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node,
  ]
}

##############################################################################
# EKS Managed Add-ons
# Versions should be pinned for reproducibility — query latest with:
#   aws eks describe-addon-versions --kubernetes-version 1.30 --addon-name <name>
##############################################################################

locals {
  addons = {
    vpc-cni            = "v1.18.1-eksbuild.1"
    coredns            = "v1.11.1-eksbuild.9"
    kube-proxy         = "v1.30.0-eksbuild.3"
    aws-ebs-csi-driver = "v1.31.0-eksbuild.1"
  }
}

resource "aws_eks_addon" "this" {
  for_each = local.addons

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = each.key
  addon_version            = each.value
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.default]
}
