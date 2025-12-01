# backend configuration
terraform {
#   backend "s3" {
#     bucket = "amal-s3-bucket-terraform30days-1"
#     key    = "dev/terraform.tfstate"
#     region = "us-east-1"
#     encrypt = true
#     use_lockfile = true
#   }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # the service will run on us-east-1
}

# create a variable
variable "environment" {
  default = "dev"
  type = string
}

variable "learner" {
    default = "amal"
    type = string
}

variable "region"{
    default = "us-east-1"
    type = string
}

# local variables
locals {
    bucket_name = "${var.learner}-bucket-terraform30days-${var.environment}-${var.region}"
    vpc_name = "${var.learner}-vpc-${var.environment}"
    ec2_name = "${var.learner}-ec2-${var.environment}"
    region = var.region
}

# create a s3 bucket
resource "aws_s3_bucket" "first_s3_bucket" {
  bucket = local.bucket_name # name of the bucket, unique one
  tags = {
    Name        = local.bucket_name #calling the environment variable
    Environment = var.environment
  }
}

# create a vpc
resource "aws_vpc" "sample" {
    region = local.region
    cidr_block = "10.0.0.0/16"
    tags = {
        Name        = local.vpc_name
        Environment = var.environment
    }
}

resource "aws_instance" "example" {
    instance_type = "t3.micro"
    region = local.region
    ami = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    # subnet_id   = aws_subnet.my_subnet.id
    tags = {
      Name        = local.ec2_name
      Environment = var.environment
    }
}

output "vpc_id" {
    value = aws_vpc.sample.id
}

output "ec2_id" {
    value = aws_instance.example.id
}