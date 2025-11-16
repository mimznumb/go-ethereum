variable "name" {
  description = "Base name for VPC resources"
  type        = string
  default     = "geth-devnet"
}

variable "cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
