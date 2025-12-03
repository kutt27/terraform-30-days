resource "aws_instance" "example_instance" {
  ami           = "ami-0ff8a91507f77f867"
  count = var.instance_count
  # instance_type = "t3.micro"
  # checks that if the var.environment is dev, it yes the instance type is t2.micro else t3.micro
  instance_type = var.environment == "dev" ? "t2.micro" : "t3.micro"
  tags = var.tags
}

locals {
  all_instance_id = aws_instance.example_instance[*].id
}

output "instances" {
  value = local.all_instance_id
}

resource "aws_security_group" "ingress_rule" {
  name   = "sg"
  # dynamic block
  dynamic "ingress" {
    for_each = var.ingress_rule
    content{
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  egress  = []
}

# resource "aws_security_group" "ingress_rule" {
#   name   = "sg"

#   ingress = [
#     {
#       from_port = 80
#       to_port = 80
#       protocol = "http"
#       cidr_blocks = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = []
#       prefix_list_ids  = []
#       security_groups  = []
#       self             = false
#       description = "Allow HTTP from anywhere"
#     }
#   ]
#   egress  = []
# }