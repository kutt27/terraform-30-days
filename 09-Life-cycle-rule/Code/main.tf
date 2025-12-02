resource "aws_instance" "ec2_instance" {
  ami = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = var.ec2_allowed_types[1]
  region = var.region
  monitoring = var.monitoring_enabled
  associate_public_ip_address = var.public_ip_association
  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags,
      monitoring,
      associate_public_ip_address
    ]
  }
}

resource "aws_instance" "ec2_instance" {
  ami = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = var.ec2_allowed_types[1]
  region = var.region
  monitoring = var.monitoring_enabled
  associate_public_ip_address = var.public_ip_association
  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "critical_data" {
  bucket = "my-critical-production-data"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "ec2_instance" {
  ami = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = var.ec2_allowed_types[1]
  region = var.region
  monitoring = var.monitoring_enabled
  associate_public_ip_address = var.public_ip_association
  tags = var.tags

#   lifecycle {
#     replace_triggered_by = [
#     #   var.subnet_id
#     ]
#   }
}

resource "aws_instance" "ec2_instance" {
  ami = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = var.ec2_allowed_types[1]
  region = var.region
  monitoring = var.monitoring_enabled
  associate_public_ip_address = var.public_ip_association
  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.tags) > 0
      error_message = "Tags must be provided."
    }

    postcondition {
      condition     = self.instance_state == "running"
      error_message = "Instance did not start successfully."
    }
  }
}
