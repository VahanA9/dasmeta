provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "dasmeta-eks-platform"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }
}
