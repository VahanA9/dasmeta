# Deployment Guide

## 1. Prerequisites

Required tools:

| Tool | Purpose |
|---|---|
| AWS CLI | AWS authentication and management |
| Terraform (>= 1.5.7) | Infrastructure and platform management |
| kubectl | Kubernetes management |
| Helm | Kubernetes package management |
| Git | Source control |

Verify installations:

```bash
aws --version
terraform version
kubectl version --client
helm version
git --version
```

Configure AWS credentials and verify access:

```bash
aws configure
aws sts get-caller-identity
```

The deployment uses AWS region `us-east-1`. Ensure your AWS identity has the required permissions to manage AWS resources, EKS, IAM, S3 state and Kubernetes workloads.

## 2. Terraform Backend

Both projects use the same S3 bucket with separate state files.

| Setting | Infrastructure | Platform |
|---|---|---|
| S3 Bucket | `terraform-dasmeta` | `terraform-dasmeta` |
| State Key | `eks-infra/terraform.tfstate` | `eks-platform/terraform.tfstate` |
| Region | `us-east-1` | `us-east-1` |
| Encryption | Enabled | Enabled |
| State Locking | S3 lockfile | S3 lockfile |

The S3 bucket must exist before running `terraform init`. The deployment identity must have access to the bucket and state objects.

**Important:** Preserve the backend bucket during cleanup.

## 3. Clone and Prepare the Repository

```bash
git clone <repository-url>
cd dasmeta
```

Format all Terraform configurations:

```bash
cd terraform
terraform fmt -recursive
```

Each Terraform project must be initialized and validated independently.

## 4. Deploy Infrastructure

Navigate to the Infrastructure project:

```bash
cd infrastructure
terraform init
terraform validate
```

Before deployment, ensure your current public IP is allowed by the configured `admin_cidr` variable.

Review and deploy:

```bash
terraform plan
terraform apply
```

Infrastructure provisions:

- VPC, public/private subnets and NAT Gateway
- Amazon EKS cluster and managed node group
- EKS add-ons
- IAM roles, policies and Pod Identity associations

Check the outputs:

```bash
terraform output
```

## 5. Configure Kubernetes Access

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dasmeta-eks
```

Verify cluster connectivity:

```bash
kubectl get nodes
kubectl get storageclass
```

The nodes should be in `Ready` state before deploying the Platform.

## 6. Deploy Platform

Navigate to the Platform project:

```bash
cd ../platform
terraform init
terraform validate
```

Review and deploy:

```bash
terraform plan
terraform apply
```

Platform deploys:

- AWS Load Balancer Controller
- StorageClass
- Podinfo application
- Prometheus and Grafana
- Loki and Grafana Alloy
- Monitoring dashboards and alerting ConfigMaps

Platform reads the EKS cluster information from the Infrastructure Terraform remote state.

## 7. Verify Deployment

Check application and monitoring workloads:

```bash
kubectl get pods -n application
kubectl get ingress -n application
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get pvc -n monitoring
```

Verify that application and monitoring Pods are healthy and persistent volume claims are `Bound`.

The Podinfo Ingress should receive an internet-facing AWS Application Load Balancer address.

### Local Access to Monitoring

Run the required port-forward command in a separate terminal.

| Component | Command | URL |
|---|---|---|
| Grafana | `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80` | http://localhost:3000 |
| Prometheus | `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090` | http://localhost:9090 |
| Alertmanager | `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093` | http://localhost:9093 |
| Loki | `kubectl port-forward -n monitoring svc/loki 3100:3100` | http://localhost:3100 |

Verify Grafana data sources, dashboards and the High CPU Usage and High Memory Usage alert rules.

The Slack contact point currently uses a placeholder webhook URL; real Slack notifications are not configured.

## 8. Troubleshooting

**Pod status and events:**

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Helm release status:**

```bash
helm list -A
helm status <release-name> -n <namespace>
helm history <release-name> -n <namespace>
```

**AWS Load Balancer Controller:**

```bash
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl get endpoints aws-load-balancer-webhook-service -n kube-system
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=100
```

Terraform manages the Platform Helm releases. Prefer resolving release issues through Terraform rather than manually uninstalling releases.

## 9. Cleanup

**Always destroy Platform before Infrastructure.**

### 9.1. Destroy Platform

```bash
cd terraform/platform
terraform plan -destroy
terraform destroy
```

Wait for the Helm releases and AWS load balancers created by the controller to be cleaned up.

### 9.2. Destroy Infrastructure

```bash
cd ../infrastructure
terraform plan -destroy
terraform destroy
```

This removes the Terraform-managed AWS infrastructure, including EKS, networking and node groups.

**Important:**

- Never destroy Infrastructure before Platform.
- Check that associated AWS load balancers have been removed.
- Review destruction plans before confirming.
- Preserve the S3 backend bucket `terraform-dasmeta`.
- Persistent EBS volumes and other retained resources may require separate cleanup and can continue generating charges.

AWS resources such as EKS, NAT Gateway, EC2 instances, load balancers and EBS volumes may incur costs while running.