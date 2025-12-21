# ALB Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where ALB will be placed"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (ALB requires at least 2 AZs for public, but we'll use just one for now, or mock it)"
  type        = list(string)
}

variable "target_id" {
  description = "ID of the target (EC2 instance)"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}
