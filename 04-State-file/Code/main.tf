# backend configuration
terraform {
  backend "s3" {
    bucket = "amal-s3-bucket-terraform30days-1"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
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

# create a s3 bucket
resource "aws_s3_bucket" "first_s3_bucket" {
  bucket = "amal-s3-bucket-terraform30days-1234" # name of the bucket, unique one

  tags = {
    Name        = "My bucket 2.0"
    Environment = "Dev"
  }
}