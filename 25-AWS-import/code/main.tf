terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "ec2" {
  ami           = "ami-03f9680ef0c07a3d1"
  instance_type = "t2.micro"
  tags = {
    Name = "test-tf-ec2"
  }
}
