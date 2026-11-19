
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project                             = "dasmeta-eks-platform"
    Environment                         = "dev"
    ManagedBy                           = "Terraform"
    "kubernetes.io/cluster/dasmeta-eks" = "shared"
  }
}

module "vpc" {
  source = "./modules/vpc"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs = local.azs

  private_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  tags = local.common_tags
}


module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = "1.37"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  admin_cidr = var.admin_cidr

  tags = local.common_tags

}
