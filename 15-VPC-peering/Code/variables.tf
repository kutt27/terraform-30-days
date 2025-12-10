variable "environment" {
  default = "dev"
  type = string
}

variable "primary"{
    default = "us-east-1"
    type = string
}

variable "secondary" {
  default = "us-west-2"
  type = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
    type = number
}

variable "primary_vpc_cidr" {
  default = "10.0.0.0/16"
  type = string
}

variable "secondary_vpc_cidr" {
  default = "10.1.0.0/16"
  type = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "primary_key_name" {
  description = "Name of the SSH key pair for Primary VPC instance (us-east-1)"
  type        = string
  default     = ""
}

variable "secondary_key_name" {
  description = "Name of the SSH key pair for Secondary VPC instance (us-west-2)"
  type        = string
  default     = ""
}