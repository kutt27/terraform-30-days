# Primary VPC
resource "aws_vpc" "primary_vpc" {
  cidr_block       = var.primary_vpc_cidr
  provider = aws.primary
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Primary-VPC-${var.primary}"
  }
}

# Secondary VPC
resource "aws_vpc" "secondary_vpc" {
  cidr_block       = var.secondary_vpc_cidr
  provider = aws.secondary
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Secondary-VPC-${var.secondary}"
  }
}

# Subnet in Primary VPC
resource "aws_subnet" "primary_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 0)
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "Primary-Subnet-${var.primary}"
    Environment = "Demo"
  }
}


# Subnet in Secondary VPC
resource "aws_subnet" "secondary_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 0)
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "Secondary-Subnet-${var.secondary}"
    Environment = "Demo"
  }
}

# Private subnet in Primary VPC
resource "aws_subnet" "primary_private_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.primary.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name        = "Primary-Private-Subnet-${var.primary}"
    Environment = "Demo"
  }
}

# Private subnet in Secondary VPC
resource "aws_subnet" "secondary_private_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.secondary.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name        = "Secondary-Private-Subnet-${var.secondary}"
    Environment = "Demo"
  }
}

# Internet Gateway for Primary VPC
resource "aws_internet_gateway" "primary_igw" {
    provider = aws.primary
    vpc_id = aws_vpc.primary_vpc.id

    tags = {
      Name        = "Primary-IGW-${var.primary}"
      Environment = "Demo"
    }
}

# Internet Gateway for Secondary VPC
resource "aws_internet_gateway" "secondary_igw" {
    provider = aws.secondary
    vpc_id = aws_vpc.secondary_vpc.id

    tags = {
      Name        = "Secondary-IGW-${var.secondary}"
      Environment = "Demo"
    }
}

# Route table for Primary VPC
resource "aws_route_table" "primary_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
      Name        = "Primary-RT-${var.primary}"
      Environment = "Demo"
  }
}

# Route table for Secondary VPC
resource "aws_route_table" "secondary_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
      Name        = "Secondary-RT-${var.secondary}"
      Environment = "Demo"
  }
}

# Associate the route table with the subnet in Primary VPC
resource "aws_route_table_association" "primary_rta" {
  provider = aws.primary
  subnet_id = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

# Associate the route table with the subnet in Primary VPC
resource "aws_route_table_association" "secondary_rta" {
  provider = aws.secondary
  subnet_id = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

# VPC Peering Connection Requester (Requester side - Primary VPC)
resource "aws_vpc_peering_connection" "primary_to_secondary_peering" {
  provider    = aws.primary
  vpc_id      = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  peer_region = var.secondary
  auto_accept = false

  tags = {
    Name        = "Primary-to-Secondary-Peering"
    Environment = "Demo"
    Side        = "Requester"
  }
}

# VPC Peering Connection Accepter (Accepter side - Secondary VPC) - Acceptor
resource "aws_vpc_peering_connection_accepter" "secondary_peering_accepter" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_peering.id
  auto_accept               = true

  tags = {
    Name        = "Secondary-Peering-Accepter"
    Environment = "Demo"
    Side        = "Accepter"
  }
}

# Add route to Secondary VPC in Primary route table
resource "aws_route" "primary_to_secondary" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.primary_rt.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_peering.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_peering_accepter]
}

# Add route to Primary VPC in Secondary route table
resource "aws_route" "secondary_to_primary" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.secondary_rt.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_peering.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_peering_accepter]
}

# Security Group for Primary VPC EC2 instance
resource "aws_security_group" "primary_sg" {
  provider    = aws.primary
  name        = "primary-vpc-sg"
  description = "Security group for Primary VPC instance"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  ingress {
    description = "HTTP from Secondary VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  ingress {
    description = "HTTPS from Secondary VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  egress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Primary-VPC-SG"
    Environment = "Demo"
  }
}

# Security Group for Secondary VPC EC2 instance
resource "aws_security_group" "secondary_sg" {
  provider    = aws.secondary
  name        = "secondary-vpc-sg"
  description = "Security group for Secondary VPC instance"
  vpc_id      = aws_vpc.secondary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  ingress {
    description = "HTTP from Secondary VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  ingress {
    description = "HTTPS from Secondary VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }


  egress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Secondary-VPC-SG"
    Environment = "Demo"
  }
}

# EC2 Instance in Primary VPC
resource "aws_instance" "primary_instance" {
  provider               = aws.primary
  ami                    = data.aws_ami.primary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  key_name               = var.primary_key_name

  user_data = local.primary_user_data  # User data for Primary VPC instance

  tags = {
    Name        = "Primary-VPC-Instance"
    Environment = "Demo"
    Region      = var.primary
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_peering_accepter, aws_route_table_association.primary_rta]
}

# PRIMARY

# Elastic IP for NAT Gateway in Primary VPC
resource "aws_eip" "primary_nat_eip" {
  provider = aws.primary
  domain   = "vpc"
}

# NAT Gateway in Primary public Subnet
resource "aws_nat_gateway" "primary_nat_gw" {
  provider        = aws.primary
  allocation_id   = aws_eip.primary_nat_eip.id
  subnet_id       = aws_subnet.primary_subnet.id  # Must be a public subnet

  tags = {
      Name        = "Primary-NAT-GW-${var.primary}"
      Environment = "Demo"
  }
}

# Private Route Table for Primary Private Subnet
resource "aws_route_table" "primary_private_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary_nat_gw.id
  }

  tags = {
      Name        = "Primary-NAT-GW-${var.primary}"
      Environment = "Demo"
  }
}

# Associate the private route table with the private subnet in Primary VPC
resource "aws_route_table_association" "primary_private_rta" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_private_subnet.id
  route_table_id = aws_route_table.primary_private_rt.id
}

# SECONDARY

# Elastic IP for NAT Gateway in Primary VPC
resource "aws_eip" "secondary_nat_eip" {
  provider = aws.secondary
  domain   = "vpc"
}

# NAT Gateway in Primary public Subnet
resource "aws_nat_gateway" "secondary_nat_gw" {
  provider        = aws.secondary
  allocation_id   = aws_eip.secondary_nat_eip.id
  subnet_id       = aws_subnet.secondary_subnet.id  # Must be a public subnet

  tags = {
      Name        = "Secondary-NAT-GW-${var.secondary}"
      Environment = "Demo"
  }
}

# Private Route Table for Secondary Private Subnet
resource "aws_route_table" "secondary_private_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.secondary_nat_gw.id
  }

  tags = {
      Name        = "Secondary-NAT-GW-${var.secondary}"
      Environment = "Demo"
  }
}

# Associate the private route table with the private subnet in Primary VPC
resource "aws_route_table_association" "secondary_private_rta" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_private_subnet.id
  route_table_id = aws_route_table.secondary_private_rt.id
}

# S3 Bucket for Flow Logs
resource "aws_s3_bucket" "flow_logs_bucket" {
  bucket = "amals-vpc-flow-logs-15"
}


resource "aws_iam_role" "flow_logs_role" {
  name = "vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for Flow Logs
resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs for Primary VPC
resource "aws_flow_log" "primary_vpc_flow_log" {
  provider           = aws.primary
  log_destination    = aws_s3_bucket.flow_logs_bucket.arn
  iam_role_arn       = aws_iam_role.flow_logs_role.arn
  traffic_type       = "ALL"
  vpc_id             = aws_vpc.primary_vpc.id
}

# VPC Flow Logs for Secondary VPC
resource "aws_flow_log" "secondary_vpc_flow_log" {
  provider           = aws.secondary
  log_destination    = aws_s3_bucket.flow_logs_bucket.arn
  iam_role_arn       = aws_iam_role.flow_logs_role.arn
  traffic_type       = "ALL"
  vpc_id             = aws_vpc.secondary_vpc.id
}

