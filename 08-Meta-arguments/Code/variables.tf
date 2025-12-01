variable "environment" {
  default = "dev"
  type = string
}

variable "region"{
    default = "us-east-1"
    type = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
    type = number
}

variable "monitoring_enabled" {
  description = "Enable detailed monitoring for EC2 instances"
    type = bool
    default = true
}

variable "public_ip_association" {
  description = "Associate a public IP address with the EC2 instances"
    type = bool
    default = true
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type = list(string)
  default = ["10.0.0.0/16", "192.168.0.0/16", "172.16.0.0/16"]
}

variable "ec2_allowed_types" {
  description = "Allowed types for EC2 instances"
  type = list(string)
  default = ["t3.micro", "t3.small", "t3.medium", "t2.micro", "t2.small", "t2.medium"]
}

variable "allowed_region" {
  description = "Allowed regions for the VPC"
  type = set(string)
  default = ["us-east-1", "us-west-2", "eu-west-1"]
}

variable "tags" {
  type = map(string)
  default = {
      Name        = "dev-EC2-Instance"
      Environment = "dev"
      created_by  = "amal"
  }
}

variable "ingress_values" {
  type = tuple([ number, string, number ]) # sequence matters
  default = [ 443, "tcp", 443 ]
  
}

variable "config" {
  type = object({
    region = string,
    monitoring = bool,
    instance_count = number
  })
  default = {
    instance_count = 1
    monitoring = true
    region = "us-east-1"
  }
}

variable "bucket_names" {
  description = "List of bucket names"
  type = list(string)
  default = ["amal-s3-bucket-terraform30days-1", "amal-s3-bucket-terraform30days-2"]
}

variable "bucket_name_set" {
  description = "List of bucket names"
  type = set(string)
  default = ["amal-s3-bucket-terraform30days-10", "amal-s3-bucket-terraform30days-20"]
}