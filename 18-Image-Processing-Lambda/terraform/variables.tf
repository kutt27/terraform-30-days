variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "image-processor"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 1024
}

variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "watermark_text" {
  description = "Text to use for image watermark"
  type        = string
  default     = "Image Processor"
}

variable "watermark_enabled" {
  description = "Whether to enable watermarking"
  type        = string
  default     = "true"
}

variable "watermark_opacity" {
  description = "Watermark opacity (0-255)"
  type        = string
  default     = "128"
}

variable "notification_email" {
  description = "Email address for SNS notifications (optional)"
  type        = string
  default     = ""
}
