terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-amals"
    key    = "terraform-day19.tfstate"
    region = "us-east-1"
  }
}
