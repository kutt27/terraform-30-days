locals {
  s3_origin_id = "S3-${aws_s3_bucket.s3_bucket.id}"
#   my_domain = "amal.com"
}

locals {
  domain_name = "filesiiet.in" 
  s3_origin_id = "S3-Static-Website"
}