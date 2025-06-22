terraform {
  required_version = "~> 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }
}

# AWS access settings
provider "aws" {
  region                   = var.aws_region
  shared_config_files      = [var.shared_config_files]
  shared_credentials_files = [var.shared_credentials_files]
  default_tags {
    tags = var.default_tags
  }
}