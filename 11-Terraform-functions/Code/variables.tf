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
