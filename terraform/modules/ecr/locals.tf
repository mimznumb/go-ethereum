locals {
  lifecycle_policies = {
    for name, cfg in var.repositories :
    name => jsonencode({
      rules = concat(
        // 1) Expire untagged images first (lowest number = evaluated first)
        cfg.expire_untagged_after_days == null ? [] : [
          {
            rulePriority = 1
            description  = "Expire untagged after ${cfg.expire_untagged_after_days} days"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = cfg.expire_untagged_after_days
            }
            action = { type = "expire" }
          }
        ],

        // 2) Keep last N images for ANY tags — must be evaluated LAST
        [
          {
            rulePriority = cfg.expire_untagged_after_days == null ? 1 : 100
            description  = "Keep last ${cfg.lifecycle_keep} images (any tags)"
            selection = {
              tagStatus   = "any"
              countType   = "imageCountMoreThan"
              countNumber = cfg.lifecycle_keep
            }
            action = { type = "expire" }
          }
        ]
      )
    })
  }
}
