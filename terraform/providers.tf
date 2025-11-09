provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket  = "mariya-demo-test"
    key     = "geth/infra/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}