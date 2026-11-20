
# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.14.0"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = data.terraform_remote_state.infrastructure.outputs.cluster_name
      region      = var.aws_region
      vpcId       = data.terraform_remote_state.infrastructure.outputs.vpc_id

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
      }
    })
  ]
}

# StorageClass
resource "helm_release" "storageclass" {
  name      = "storageclass"
  chart     = "${path.module}/helm/storageclass"
  namespace = "kube-system"

  wait    = true
  timeout = 300
}

# Podinfo
resource "helm_release" "podinfo" {
  name             = "podinfo"
  chart            = "${path.module}/../../helm/charts/podinfo"
  namespace        = "application"
  create_namespace = true

  wait    = true
  timeout = 900

  values = [
    file("${path.module}/helm/podinfo/values.yaml")
  ]

  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}

# Prometheus
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "93.4.1"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/helm/monitoring/prometheus-values.yaml")
  ]

  depends_on = [
    helm_release.storageclass,
    helm_release.monitoring_dashboards
  ]
}

# Loki
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = "7.7.0"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/helm/monitoring/loki-values.yaml")
  ]

  depends_on = [
    helm_release.storageclass,
    helm_release.aws_load_balancer_controller
  ]
}

# Grafana Alloy
resource "helm_release" "alloy" {
  name       = "alloy"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.16.0"
  namespace  = "monitoring"

  values = [
    file("${path.module}/helm/monitoring/alloy-values.yaml")
  ]

  depends_on = [
    helm_release.loki
  ]
}

# Monitoring Dashboards
resource "helm_release" "monitoring_dashboards" {
  name             = "monitoring-dashboards"
  chart            = "${path.module}/helm/monitoring"
  namespace        = "monitoring"
  create_namespace = true

  depends_on = [
    helm_release.loki,
    helm_release.alloy,
    helm_release.podinfo
  ]
}
