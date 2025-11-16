locals {
  tags = merge(
    {
      Project   = "geth-devnet"
      Terraform = "true"
    },
    var.tags
  )

  irsa = {
    name      = var.irsa_service_account_name
    namespace = var.irsa_service_account_namespace
  }
}
