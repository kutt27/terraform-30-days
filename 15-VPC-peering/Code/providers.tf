terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary
}

