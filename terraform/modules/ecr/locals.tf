
locals {
  # Normalize repository lifecycle policy JSON per repo
  lifecycle_policies = {
    for name, cfg in var.repositories :
    name => jsonencode({
      rules = concat(
        [
          {
            rulePriority = 1
            description  = "Keep last ${cfg.lifecycle_keep} images"
            selection = {
              tagStatus   = "tagged"
              countType   = "imageCountMoreThan"
              countNumber = cfg.lifecycle_keep
            }
            action = { type = "expire" }
          }
        ],
        cfg.expire_untagged_after_days == null ? [] : [
          {
            rulePriority = 2
            description  = "Expire untagged after ${cfg.expire_untagged_after_days} days"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = cfg.expire_untagged_after_days
            }
            action = { type = "expire" }
          }
        ]
      )
    })
  }
}
