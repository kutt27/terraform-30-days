terraform {
  backend "s3" {
    bucket       = "staging-my-terraform-bucket-kutt27"
    key          = "terraform/state/main/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
