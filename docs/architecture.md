# Architecture

## 1. Overview

The platform runs a containerized application on Amazon EKS. AWS infrastructure is provisioned using Terraform, while Kubernetes workloads are deployed and managed with Helm.

The architecture includes:

- AWS networking and infrastructure
- Amazon EKS cluster
- Kubernetes application workloads
- Monitoring and logging stack
- Public application access

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

Grafana dashboards are provisioned using ConfigMaps managed through Helm.

Two alert rules are configured:

- High CPU Usage
- High Memory Usage

Persistent storage is configured for Loki and Grafana using Amazon EBS volumes.

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

Terraform manages AWS infrastructure and Helm releases.

The project uses reusable modules to separate VPC and EKS configuration.

### 7.1. Project Structure

```text
terraform/
├── environments/
├── modules/
│   ├── eks/
│   │   ├── lbc-iam-policy.json
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── .terraform.lock.hcl
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
└── versions.tf
```

### 7.2. Terraform Modules

**VPC Module (`modules/vpc/`)**

Responsible for:

- Creating the VPC
- Creating public and private subnets
- Configuring routing
- Creating the NAT Gateway

**EKS Module (`modules/eks/`)**

Responsible for:

- Creating the EKS cluster
- Creating the managed node group
- Configuring EKS add-ons
- Creating IAM roles and policies
- Configuring Pod Identity associations

The root Terraform configuration also manages Helm releases for Kubernetes components.

### 7.3. Terraform State

Terraform state is stored remotely in Amazon S3.

| Setting | Value |
|---|---|
| Bucket | `terraform-dasmeta` |
| State Key | `eks-platform/terraform.tfstate` |
| Encryption | Enabled |
| Versioning | Enabled |
| State Locking | S3 lockfile |

The S3 backend bucket must exist before Terraform initialization.

The `.terraform.lock.hcl` file is committed to Git to keep provider versions consistent.

Terraform state files and generated execution plans should not be committed to Git.

## 8. Cost and Availability Considerations

The infrastructure uses several cost-saving choices:

- Spot instances for worker nodes
- One shared NAT Gateway
- Two worker nodes
- Managed Kubernetes add-ons

These choices have trade-offs:

- Spot instances can be interrupted.
- A single NAT Gateway is a potential availability bottleneck.
- Two worker nodes provide limited capacity during maintenance or interruptions.

Review AWS costs and availability requirements before deploying the platform.