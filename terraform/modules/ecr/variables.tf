variable "enable_registry_scanning" {
  description = "Configure ECR registry-level enhanced scanning."
  type        = bool
  default     = true
}

variable "registry_scan_frequency" {
  description = "Registry scanning frequency when enhanced scanning enabled."
  type        = string
  default     = "SCAN_ON_PUSH" # or CONTINUOUS_SCAN
}

variable "registry_repository_filter" {
  description = "Which repositories the registry scanning rule applies to."
  type        = string
  default     = "*"
}

variable "registry_policy_json" {
  description = "Optional registry-wide policy JSON (string). Null to skip."
  type        = string
  default     = null
}

variable "replication_rules" {
  description = <<EOT
Optional ECR replication rules. List of objects:
[
  {
    destination_region = "eu-west-1"
    destination_registry_id = null # or account id string
    filter_type = "PREFIX_MATCH"
    filter      = "geth-"
  }
]
EOT
  type = list(object({
    destination_region      = string
    destination_registry_id = string
    filter_type             = string # "PREFIX_MATCH" or "WILDCARD"
    filter                  = string
  }))
  default = []
}

variable "repositories" {
  description = <<EOT
Map of repositories to create. Key = repo name, value = settings:
{
  "geth-base" = {
    mutable          = true
    scan_on_push     = true
    encryption       = "AES256" # or "KMS"
    kms_key_arn      = null
    lifecycle_keep   = 30
    expire_untagged_after_days = null # e.g., 14 to expire untagged images
    tags             = { role = "base" }
  }
}
EOT
  type = map(object({
    mutable                    = bool
    scan_on_push               = bool
    encryption                 = string # "AES256" or "KMS"
    kms_key_arn                = string # required if encryption == "KMS"
    lifecycle_keep             = number # keep last N images (any tags)
    expire_untagged_after_days = number # null to skip
    tags                       = map(string)
  }))
}

variable "tags" {
  description = "Common tags applied to created resources."
  type        = map(string)
  default     = {}
}
