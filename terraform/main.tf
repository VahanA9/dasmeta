
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

resource "helm_release" "podinfo" {
  name             = "podinfo"
  chart            = "${path.module}/../helm/charts/podinfo"
  namespace        = "application"
  create_namespace = true

  values = [
    file("${path.module}/../helm/podinfo/values.yaml")
  ]

  depends_on = [module.eks]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "93.4.1"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/../helm/monitoring/prometheus-values.yaml")
  ]

  depends_on = [
    module.eks,
    helm_release.monitoring_dashboards
  ]
}

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = "7.7.0"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/../helm/monitoring/loki-values.yaml")
  ]

  depends_on = [module.eks]
}

resource "helm_release" "alloy" {
  name       = "alloy"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.16.0"
  namespace  = "monitoring"

  values = [
    file("${path.module}/../helm/monitoring/alloy-values.yaml")
  ]

  depends_on = [helm_release.loki]
}

resource "helm_release" "monitoring_dashboards" {
  name             = "monitoring-dashboards"
  chart            = "${path.module}/../helm/monitoring"
  namespace        = "monitoring"
  create_namespace = true

  depends_on = [
    helm_release.loki,
    helm_release.alloy,
    helm_release.podinfo
  ]
}

