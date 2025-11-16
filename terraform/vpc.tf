module "vpc" {
  source = "./modules/vpc"

  name = "geth-devnet"
  cidr = "10.10.0.0/16"
  azs  = ["eu-central-1a", "eu-central-1b"]
}