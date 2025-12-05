# Assignment 1: Project Naming
locals {
  project_name_raw = "Project AMAL Resource"
  project_name     = lower(replace(local.project_name_raw, " ", "-"))
}

# Assignment 2: Resource Tagging
locals {
  default_tags = {
    Project = local.project_name
    Owner   = "amal"
  }
  env_tags = {
    Environment = "production"
    Region      = "us-east-1"
  }
  merged_tags = merge(local.default_tags, local.env_tags)
}

# Assignment 3: S3 Bucket Naming
locals {
  bucket_name_raw = "Project AMaL Resource"
  bucket_name     = lower(replace(substr(local.bucket_name_raw, 0, 63), " ", "-"))
}

# Assignment 4: Security Group Ports
locals {
  port_string = "80,443,8080"
  port_list   = split(",", local.port_string)
  sg_rules    = [
    for port in local.port_list : {
      from_port   = port
      to_port     = port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Assignment 5: Environment Lookup
locals {
  instance_sizes = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
  selected_env = "prod"
  instance_type = lookup(local.instance_sizes, local.selected_env, "t3.micro")
}

# Assignment 6: Instance Validation
locals {
  instance_type_input = "t3.micro"
  valid_instance      = can(regex("^t[2-4]\\.[a-z]+", local.instance_type_input)) && length(local.instance_type_input) > 0
}

# Assignment 7: Backup Configuration
locals {
  backup_name = "backup-config"
  sensitive   = sensitive("backup-key")
}

# Assignment 8: File Path Processing
locals {
  file_path = "/var/log/app.log"
  dir_name  = dirname(local.file_path)
  file_exists = fileexists(local.file_path)
}

# Assignment 9: Location Management
locals {
  regions = toset(["ap-south-1", "us-east-1", "ap-south-1", "eu-west-1"])
  all_regions = concat(["ap-south-1"], regions)
}

# Assignment 10: Cost Calculation
locals {
  credits = -10
  costs   = [100, 50, 200]
  net_cost = sum([for c in local.costs : max(c + local.credits, 0)])
}

# Assignment 11: Timestamp Management
locals {
  current_timestamp = timestamp()
  formatted_date    = formatdate("YYYY-MM-DD", local.current_timestamp)
}

# Assignment 12: File Content Handling
locals {
  config_json = file("${path.module}/config.json")
  config_data = jsondecode(local.config_json)
  secret_data = jsonencode(local.config_data)
}
