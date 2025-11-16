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

  tags = {
    Environment = "dev"
  }

  github_deploy_role_arn = aws_iam_role.github_eks_deploy.arn
}