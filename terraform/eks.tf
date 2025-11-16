module "eks" {
  source = "./modules/eks"

  cluster_name       = "geth-devnet-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  desired_size = 1
  min_size     = 1
  max_size     = 2

  irsa_enabled                   = true
  irsa_service_account_name      = "geth-devnet-sa"
  irsa_service_account_namespace = "default"

  manage_aws_auth = true

  aws_auth_roles = [
    # GitHub Actions role for Helm deploy
    {
      rolearn  = aws_iam_role.github_eks_deploy.arn
      username = "github-eks-deploy"
      groups   = ["system:masters"]
    },

    # (optional) your own admin IAM user or role, if not already there
    # {
    #   rolearn  = aws_iam_role.some_admin.arn
    #   username = "admin"
    #   groups   = ["system:masters"]
    # },
  ]

  tags = {
    Environment = "dev"
  }
}