terraform {
  backend "s3" {
    bucket      = "erraform-state-1754513244"
    key         = "dev/terraform.tfstate"
    region      = "ca-central-1"
    use_lockfile  = "true"
    encrypt     = true
  }
}