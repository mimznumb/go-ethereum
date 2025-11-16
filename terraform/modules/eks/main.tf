# EKS via official module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id     = var.vpc_id
  subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"] # smallest cheap instance
      capacity_type  = "SPOT"       # save cost
      desired_size   = var.desired_size
      min_size       = var.min_size
      max_size       = var.max_size
      disk_size      = 20

      labels = { role = "geth-devnet-node" }
      tags   = local.tags
    }
  }

  enable_irsa = true
  tags        = local.tags
}

# Allow nodes to pull from ECR
resource "aws_iam_role_policy" "node_ecr_pull" {
  name = "${var.cluster_name}-ecr-pull"
  role = module.eks.eks_managed_node_groups["default"].iam_role_name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        Resource = "*"
      }
    ]
  })
}

# Optional: IRSA role for a specific SA to access AWS APIs from pods
resource "aws_iam_role" "irsa_role" {
  count = var.irsa_enabled ? 1 : 0

  name = "${var.cluster_name}-irsa-${local.irsa.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # oidc_provider is the issuer URL *without* https://
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount/${local.irsa.namespace}/${local.irsa.name}"
          }
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "irsa_ecr_readonly" {
  count      = var.irsa_enabled ? 1 : 0
  role       = aws_iam_role.irsa_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "irsa_logs" {
  count      = var.irsa_enabled ? 1 : 0
  role       = aws_iam_role.irsa_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
