# Deployment Guide

This document describes the requirements and steps for deploying the AWS EKS Platform using Terraform and Helm.

## 1. Prerequisites

Make sure the following tools are installed:

| Tool | Purpose |
|---|---|
| AWS CLI | Manage and authenticate with AWS |
| Terraform | Provision AWS infrastructure |
| kubectl | Interact with Kubernetes |
| Helm | Deploy Kubernetes applications |
| Git | Clone and manage the repository |

Verify the installations:

```bash
aws --version
terraform version
kubectl version --client
helm version
git --version
```

An AWS account with sufficient permissions to create and manage the required resources is also required.

## 2. AWS Access Configuration

Configure AWS credentials:

```bash
aws configure
```

Verify the current AWS identity:

```bash
aws sts get-caller-identity
```

The project uses the `us-east-1` region.

Check the configured region:

```bash
aws configure get region
```

Make sure the AWS credentials have the required permissions.

## 3. Terraform Backend

Terraform state is stored remotely in Amazon S3.

| Setting | Value |
|---|---|
| Bucket | `terraform-dasmeta` |
| State Key | `eks-platform/terraform.tfstate` |
| Encryption | Enabled |
| Versioning | Enabled |
| State Locking | S3 lockfile |

The S3 bucket must exist before Terraform initialization.

The AWS identity used for deployment must have access to the backend bucket.

## 4. Initialize and Validate Terraform

Clone the repository:

```bash
git clone <repository-url>
cd dasmeta
```

Go to the Terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Format the Terraform files:

```bash
terraform fmt -recursive
```

Validate the configuration:

```bash
terraform validate
```

## 5. Plan and Apply

Before deployment, make sure the current public IP address is allowed by the configured EKS administrator CIDR (`admin_cidr`).

Generate and review the execution plan:

```bash
terraform plan
```

Check which resources will be created, changed or destroyed.

When the plan has been reviewed and approved, deploy the infrastructure:

```bash
terraform apply
```

Terraform creates the required AWS resources, including:

- VPC and subnets
- NAT Gateway
- EKS cluster
- Managed node group
- EKS add-ons
- IAM roles and Pod Identity associations
- Kubernetes Helm releases

**Cost warning:** AWS resources such as EKS, NAT Gateway, load balancers and EC2 instances may generate charges while running.

## 6. Configure kubectl

After the EKS cluster is created, update the local kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name <cluster-name>
```

Verify cluster access:

```bash
kubectl get nodes
```

Check the Kubernetes namespaces:

```bash
kubectl get namespaces
```

The cluster should contain the `application` and `monitoring` namespaces.

## 7. Verify the Application

Check the Podinfo deployment:

```bash
kubectl get pods -n application
```

Check the Kubernetes service:

```bash
kubectl get svc -n application
```

Check the Ingress:

```bash
kubectl get ingress -n application
```

The AWS Load Balancer Controller should create an internet-facing Application Load Balancer for the Ingress.

## 8. Verify Monitoring and Alerting

Check monitoring components:

```bash
kubectl get pods -n monitoring
```

Check the services:

```bash
kubectl get svc -n monitoring
```

Verify that Prometheus, Grafana, Loki and Alloy are running.

To access Grafana locally, use port forwarding:

```bash
kubectl port-forward \
  svc/<grafana-service-name> \
  3000:80 \
  -n monitoring
```

Then open:

```text
http://localhost:3000
```

Confirm the exact Grafana service name and port with `kubectl get svc -n monitoring`.

In Grafana, check that the following alert rules are configured:

- High CPU Usage
- High Memory Usage

The Slack contact point currently uses a placeholder webhook URL. Real Slack notifications are not configured.

## 9. Cleanup

When the environment is no longer needed, Terraform can remove the resources:

```bash
terraform destroy
```

Review the destruction plan carefully before confirming.

The Terraform state backend bucket is managed separately and may remain after the infrastructure is destroyed.

Make sure that no resources or data you need will be deleted before running this command.