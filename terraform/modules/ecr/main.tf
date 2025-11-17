
# ---------------- Registry configuration (optional) ----------------
resource "aws_ecr_registry_scanning_configuration" "this" {
  count     = var.enable_registry_scanning ? 1 : 0
  scan_type = "ENHANCED"

  rule {
    scan_frequency = var.registry_scan_frequency
    repository_filter {
      filter      = var.registry_repository_filter
      filter_type = "WILDCARD"
    }
  }
}

resource "aws_ecr_registry_policy" "this" {
  count  = var.registry_policy_json == null ? 0 : 1
  policy = var.registry_policy_json
}

resource "aws_ecr_replication_configuration" "this" {
  count = length(var.replication_rules) == 0 ? 0 : 1

  replication_configuration {
    dynamic "rule" {
      for_each = var.replication_rules
      content {
        destination {
          region      = rule.value.destination_region
          registry_id = rule.value.destination_registry_id
        }
        repository_filter {
          filter      = rule.value.filter
          filter_type = rule.value.filter_type
        }
      }
    }
  }
}

# ---------------- Repositories ----------------
resource "aws_ecr_repository" "repo" {
  for_each             = var.repositories
  name                 = each.key
  image_tag_mutability = each.value.mutable ? "MUTABLE" : "IMMUTABLE"

  force_delete = true

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption
    kms_key         = each.value.encryption == "KMS" ? each.value.kms_key_arn : null
  }

  tags = merge(var.tags, each.value.tags)
}

resource "aws_ecr_lifecycle_policy" "repo" {
  for_each   = var.repositories
  repository = aws_ecr_repository.repo[each.key].name
  policy     = local.lifecycle_policies[each.key]
}
