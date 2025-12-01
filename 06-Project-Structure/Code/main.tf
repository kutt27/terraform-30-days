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