terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # locking the provider version to 6.x
    }
  }
}

provider "aws" {
  region = "us-east-1" # the service will run on us-east-1
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}