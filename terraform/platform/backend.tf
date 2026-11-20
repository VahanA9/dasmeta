terraform {
  backend "s3" {
    bucket       = "terraform-dasmeta"
    key          = "eks-platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}