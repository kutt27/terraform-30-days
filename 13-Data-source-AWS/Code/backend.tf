terraform {
  backend "s3" {
    bucket = "amal-s3-bucket-terraform30days-2"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}