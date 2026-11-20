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

data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "terraform-dasmeta"
    key    = "eks-infra/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.terraform_remote_state.infrastructure.outputs.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}