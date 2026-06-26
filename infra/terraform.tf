terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      managed_by = "Terraform"
    }
  }
}
