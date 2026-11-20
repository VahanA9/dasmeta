# Architecture

## 1. Overview

The platform runs a containerized application on Amazon EKS. AWS infrastructure is provisioned using Terraform, while Kubernetes workloads and platform services are deployed and managed through Helm.

The Terraform configuration is split into two independent projects:

- **Infrastructure** – manages AWS networking, Amazon EKS, IAM, node groups and EKS add-ons.
- **Platform** – manages Kubernetes applications and platform components through Helm releases.

Each project maintains its own remote Terraform state in Amazon S3.

The architecture includes:

- AWS networking and infrastructure
- Amazon EKS cluster
- Kubernetes application workloads
- Monitoring and logging stack
- Public application access
- Separate Terraform infrastructure and platform management

## 2. AWS Infrastructure

The infrastructure is deployed in the `us-east-1` AWS region.

### 2.1. VPC and Networking

The VPC uses the CIDR range `10.0.0.0/16` and spans two Availability Zones.

| Setting | Configuration |
|---|---|
| VPC CIDR | `10.0.0.0/16` |
| Availability Zones | 2 |
| Public Subnets | 2 |
| Private Subnets | 2 |
| NAT Gateway | 1 |
| DNS Support | Enabled |
| DNS Hostnames | Enabled |

Public subnets are used for internet-facing load balancers. Private subnets are used for EKS worker nodes.

The worker nodes access the internet through a shared NAT Gateway.

Kubernetes subnet tags are configured to support AWS Load Balancer Controller discovery.

The shared NAT Gateway reduces costs but introduces a single point of failure for outbound internet connectivity.

### 2.2. Amazon EKS

The Kubernetes cluster is managed by Amazon EKS.

| Setting | Configuration |
|---|---|
| Cluster Name | `dasmeta-eks` |
| Kubernetes Version | `1.37` |
| Worker Nodes | Managed Node Group |
| Instance Types | `t3.medium`, `t3a.medium` |
| Capacity Type | Spot |
| Desired Nodes | 2 |
| Minimum Nodes | 2 |
| Maximum Nodes | 2 |
| API Endpoint | Public |
| API Access | Restricted by administrator CIDR |

The EKS API endpoint is publicly accessible but restricted to the configured administrator CIDR.

Spot instances help reduce compute costs but can be interrupted by AWS.

### 2.3. EKS Add-ons

The following EKS add-ons are configured:

| Add-on | Purpose |
|---|---|
| CoreDNS | DNS resolution inside the cluster |
| kube-proxy | Kubernetes network rules |
| VPC CNI | Pod networking |
| EKS Pod Identity Agent | AWS IAM credentials for workloads |
| AWS EBS CSI Driver | Persistent storage management |

The EBS CSI Driver uses EKS Pod Identity to access the required AWS permissions.

### 2.4. IAM and Pod Identity

IAM roles provide AWS permissions to Kubernetes components.

Pod Identity associations are configured for:

- AWS EBS CSI Driver
- AWS Load Balancer Controller

This approach avoids storing AWS access keys inside Kubernetes workloads.

## 3. Kubernetes Workloads

### 3.1. Application

Podinfo is used as the demo application.

It is deployed in the `application` namespace using a custom Helm chart.

Main configuration:

- Two replicas
- ClusterIP Service
- HTTP port: `9898`
- Metrics port: `9797`
- Readiness and liveness probes
- CPU and memory requests and limits
- Pod Disruption Budget

The Podinfo Helm chart is maintained in the repository under `helm/charts/podinfo/`. Its environment-specific values are maintained in `terraform/platform/helm/podinfo/values.yaml`.

### 3.2. Monitoring and Logging

The monitoring stack runs in the `monitoring` namespace.

| Component | Responsibility |
|---|---|
| Prometheus | Metrics collection |
| Grafana | Dashboards and alerting |
| Loki | Log storage |
| Grafana Alloy | Kubernetes log collection |
| Node Exporter | Node-level metrics |
| Kube State Metrics | Kubernetes object metrics |

Grafana dashboards and alerting configuration are provisioned using ConfigMaps managed through the local monitoring Helm chart.

Two alert rules are configured:

- High CPU Usage
- High Memory Usage

Persistent storage is configured for Loki, Grafana and Prometheus using Amazon EBS volumes and the `gp3` StorageClass.

The StorageClass is managed through a separate local Helm chart.

## 4. Public Application Access

The AWS Load Balancer Controller manages AWS load balancers based on Kubernetes Ingress resources.

The controller is installed using Helm and receives AWS permissions through EKS Pod Identity.

The Podinfo Ingress is configured with:

| Setting | Configuration |
|---|---|
| Ingress Class | `alb` |
| Load Balancer Scheme | `internet-facing` |
| Target Type | `ip` |
| Listener | HTTP :80 |
| Health Check Path | `/healthz` |

The ALB forwards traffic directly to Pod IP addresses.

The Podinfo Service provides internal access to the application on port `9898`.

A custom domain, HTTPS with AWS Certificate Manager and external health monitoring are not configured yet.

## 5. Request Flow

The application request flow is:

```text
Internet
   |
   v
AWS Application Load Balancer
   |
   v
Podinfo Pods
   |
   v
Application
```

AWS Load Balancer Controller manages the ALB configuration based on the Kubernetes Ingress resource.

## 6. Monitoring and Logging Flow

### Metrics

1. Prometheus collects metrics from the Kubernetes cluster and configured targets.
2. Grafana uses Prometheus as a data source.
3. Dashboards display cluster and application metrics.
4. Grafana evaluates CPU and memory alert rules.

### Logs

1. Grafana Alloy runs as a DaemonSet on Kubernetes nodes.
2. Alloy discovers and collects Kubernetes container logs.
3. Logs are forwarded to Loki.
4. Grafana uses Loki as a log data source.

## 7. Terraform Infrastructure Management

Terraform manages AWS infrastructure and Kubernetes platform releases through two separate root configurations.

This separation provides independent lifecycle management for AWS infrastructure and Kubernetes workloads.

### 7.1. Project Structure

The Terraform project is organized as follows:

```text
terraform/
├── infrastructure/
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── modules/
│       ├── eks/
│       └── vpc/
│
├── platform/
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── versions.tf
│   └── helm/
│       ├── monitoring/
│       │   ├── Chart.yaml
│       │   ├── templates/
│       │   ├── dashboards/
│       │   ├── alerting/
│       │   ├── alloy-values.yaml
│       │   ├── loki-values.yaml
│       │   ├── prometheus-values.yaml
│       │   └── storageclass.yaml
│       ├── podinfo/
│       │   └── values.yaml
│       └── storageclass/
│           ├── Chart.yaml
│           └── templates/
│
└── README.md
```

The Podinfo Helm chart is also maintained in the repository under:

```text
helm/
└── charts/
    └── podinfo/
```

### 7.2. Infrastructure Project

The `terraform/infrastructure/` configuration is responsible for AWS resources.

It manages:

- VPC and networking
- Public and private subnets
- Routing and NAT Gateway
- Amazon EKS cluster
- Managed node groups
- EKS add-ons
- IAM roles and policies
- EKS Pod Identity associations

Reusable Terraform modules are located under `infrastructure/modules/`.

**VPC Module (`modules/vpc/`)**

Responsible for:

- Creating the VPC
- Creating public and private subnets
- Configuring routing
- Creating the NAT Gateway

**EKS Module (`modules/eks/`)**

Responsible for:

- Creating the EKS cluster
- Creating managed node groups
- Configuring EKS add-ons
- Creating IAM roles and policies
- Configuring Pod Identity associations

The Infrastructure project exposes outputs such as:

- `vpc_id`
- `private_subnets`
- `public_subnets`
- `cluster_name`
- `aws_region`

These outputs are consumed by the Platform project.

### 7.3. Platform Project

The `terraform/platform/` configuration manages Kubernetes platform components through the Terraform Helm provider.

It consumes Infrastructure outputs through the `terraform_remote_state` data source.

The Platform project manages the following Helm releases:

| Helm Release | Responsibility |
|---|---|
| AWS Load Balancer Controller | AWS load balancer integration |
| StorageClass | Kubernetes EBS StorageClass |
| Podinfo | Demo application |
| Prometheus | Metrics collection and monitoring |
| Loki | Log storage |
| Alloy | Kubernetes log collection |
| Monitoring Dashboards | Grafana dashboards and alerting ConfigMaps |

The Platform project connects to the existing EKS cluster using the cluster endpoint and certificate authority obtained from AWS.

It uses AWS CLI authentication through the Helm provider's `exec` configuration.

The Platform project does not create the VPC or EKS cluster. It consumes the outputs produced by the Infrastructure project.

### 7.4. Terraform State and Backend

Terraform state is stored remotely in Amazon S3.

Both Terraform projects use the same backend bucket but separate state keys.

| Setting | Infrastructure | Platform |
|---|---|---|
| Backend | Amazon S3 | Amazon S3 |
| Bucket | `terraform-dasmeta` | `terraform-dasmeta` |
| State Key | `eks-infra/terraform.tfstate` | `eks-platform/terraform.tfstate` |
| Region | `us-east-1` | `us-east-1` |
| Encryption | Enabled | Enabled |
| State Locking | S3 lockfile | S3 lockfile |

The S3 backend bucket must exist before Terraform initialization.

The Infrastructure and Platform states are independent. This allows each project to be planned, applied and destroyed separately.

The Platform project reads Infrastructure outputs through:

```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "terraform-dasmeta"
    key    = "eks-infra/terraform.tfstate"
    region = "us-east-1"
  }
}
```

The `.terraform.lock.hcl` file should be committed to Git to keep provider versions consistent.

Terraform state files, generated execution plans and sensitive variable files must not be committed to Git.

### 7.5. Deployment Order

The deployment process must follow this order:

**Step 1 – Infrastructure**

Initialize and deploy AWS infrastructure:

```bash
cd terraform/infrastructure

terraform init
terraform validate
terraform plan
terraform apply
```

**Step 2 – Configure Kubernetes Access**

Update the local kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dasmeta-eks
```

Verify cluster access:

```bash
kubectl get nodes
kubectl get storageclass
```

**Step 3 – Platform**

Initialize and deploy Kubernetes platform components:

```bash
cd ../platform

terraform init
terraform validate
terraform plan
terraform apply
```

The Platform project requires the Infrastructure state and a reachable EKS cluster.

### 7.6. Update and Destroy

To update infrastructure:

```bash
cd terraform/infrastructure

terraform plan
terraform apply
```

To update Kubernetes platform components:

```bash
cd terraform/platform

terraform plan
terraform apply
```

The two projects must be managed independently.

**Destroy order is important.**

Always destroy the Platform project before destroying Infrastructure:

```bash
cd terraform/platform

terraform plan -destroy
terraform destroy
```

After the Kubernetes Helm releases have been removed and AWS load balancers created by the controller have been cleaned up, destroy the Infrastructure:

```bash
cd ../infrastructure

terraform plan -destroy
terraform destroy
```

The S3 backend bucket `terraform-dasmeta` is shared infrastructure for Terraform state storage and must be preserved.

Do not delete the backend bucket when destroying the EKS environment.