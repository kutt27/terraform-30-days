# locals {
#   s3_origin_id = "S3-${aws_s3_bucket.s3_bucket.id}"
# #   my_domain = "amal.com"
# }

# locals {
#   domain_name = "filesiiet.in" 
#   s3_origin_id = "S3-Static-Website"
# }

# Local values for VPC Peering Demo

locals {
  # User data template for Primary instance
  primary_user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Primary VPC Instance - ${var.primary}</h1>" > /var/www/html/index.html
    echo "<p>Private IP: $(hostname -I)</p>" >> /var/www/html/index.html
  EOF

  # User data template for Secondary instance
  secondary_user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Secondary VPC Instance - ${var.secondary}</h1>" > /var/www/html/index.html
    echo "<p>Private IP: $(hostname -I)</p>" >> /var/www/html/index.html
  EOF
}