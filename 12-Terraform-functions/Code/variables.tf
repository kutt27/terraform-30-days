variable "project_name" {
  type    = string
  default = "Project ALPHA Resource"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "instance_type_input" {
  type    = string
  default = "t3.micro"
}

variable "credits" {
  type    = number
  default = -10
}

variable "costs" {
  type    = list(number)
  default = [100, 50, 200]
}

variable "port_string" {
  type    = string
  default = "80,443,8080"
}

variable "file_path" {
  type    = string
  default = "/var/log/app.log"
}

variable "instance_type"{
  default = "t2.micro"
  type = string
  validation {
    condition = length(var.instance_type) >= 2 && length(var.instance_type) <= 20
    error_message = "Instance type must be between 2 and 10 characters" 
  }
  validation {
    condition = can(regex("^t[2-3]\\.[a-z]+", var.instance_type))
    error_message = "Instance type must start with t2 or t3"
  }
}

variable "backup_name" {
  default = "daily-backup"
  type = string
  # validation {
  #   condition = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
  #   error_message = "Bucket name must be between 3 and 63 characters"
  # }
  validation {
    condition = endswith(var.backup_name, "-backup")
    error_message = "Backup name must end with -backup"
  }
}

variable "credentials" {
  default = "xyz123"
  sensitive = true
}