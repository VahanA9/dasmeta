provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "dasmeta-eks-infra"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }
}