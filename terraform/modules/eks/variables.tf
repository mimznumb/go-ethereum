variable "cluster_name" {
  type        = string
  default     = "geth-devnet-cluster"
  description = "EKS cluster name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to host the cluster"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for nodes"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets (also used by control plane endpoint)"
}

variable "desired_size" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "irsa_enabled" {
  type    = bool
  default = true
}

variable "irsa_service_account_name" {
  type    = string
  default = "geth-devnet-sa"
}

variable "irsa_service_account_namespace" {
  type    = string
  default = "default"
}
