module "ecr" {
  source = "../modules/ecr" # adjust path if different

  enable_registry_scanning   = true
  registry_scan_frequency    = "SCAN_ON_PUSH"
  registry_repository_filter = "*"

  repositories = {
    "geth-base" = {
      mutable                    = true
      scan_on_push               = true
      encryption                 = "AES256"
      kms_key_arn                = null
      lifecycle_keep             = 2
      expire_untagged_after_days = 14
      tags                       = { role = "base" }
    }

    "geth-devnet" = {
      mutable                    = true
      scan_on_push               = true
      encryption                 = "AES256"
      kms_key_arn                = null
      lifecycle_keep             = 2
      expire_untagged_after_days = 14
      tags                       = { role = "devnet" }
    }

    "geth-devnet-pre" = {
      mutable                    = true
      scan_on_push               = true
      encryption                 = "AES256"
      kms_key_arn                = null
      lifecycle_keep             = 30
      expire_untagged_after_days = 14
      tags                       = { role = "predeployed" }
    }
  }

  tags = {
    project = "go-ethereum-devnet"
    owner   = "devops"
  }
}
