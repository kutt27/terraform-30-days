terraform {
  backend "s3" {
    bucket = "amal-day-29-terraform"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
