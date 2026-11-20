# Operations Guide

This document describes monitoring, logging, alerting, public application access and troubleshooting for the AWS EKS Platform.

## 1. Monitoring and Logging

The monitoring stack runs in the `monitoring` namespace.

| Component | Purpose |
|---|---|
| Prometheus | Collects and stores metrics |
| Grafana | Dashboards and alert management |
| Loki | Log aggregation and storage |
| Grafana Alloy | Collects Kubernetes container logs |
| Node Exporter | Provides node-level metrics |
| Kube State Metrics | Provides Kubernetes object metrics |

### 1.1. Prometheus

Prometheus collects metrics from the Kubernetes environment, including:

- Node CPU and memory usage
- Kubernetes resource metrics
- Pod and container metrics
- Application metrics exposed by Podinfo

Node Exporter and Kube State Metrics provide additional infrastructure and Kubernetes metrics.

### 1.2. Grafana

Grafana provides dashboards for monitoring:

- Node resource usage
- Kubernetes workloads
- Pod and container resources
- Application metrics

Dashboards are provisioned through the custom Helm chart.

### 1.3. Loki and Grafana Alloy

Loki is used for centralized log storage.

Grafana Alloy runs as a DaemonSet, collects Kubernetes container logs and forwards them to Loki.

Logs can be explored through Grafana.

### 1.4. Persistent Storage

Persistent storage uses Amazon EBS volumes through the AWS EBS CSI Driver.

| Component | Storage |
|---|---:|
| Loki | 10 GiB |
| Grafana | 5 GiB |

## 2. Alerting

Grafana Alerting is configured with two alert rules.

| Alert | Condition | Duration |
|---|---|---|
| High CPU Usage | CPU above 80% | 5 minutes |
| High Memory Usage | Memory above 85% | 5 minutes |

These alerts help identify resource pressure in the Kubernetes environment.

### Notifications

A Slack contact point and notification policy are included as examples.

The webhook URL is a placeholder. Real Slack integration has not been configured or tested.

## 3. Accessing Grafana

Grafana can be accessed locally using Kubernetes port forwarding.

First, check the service name and port:

```bash
kubectl get svc -n monitoring
```

Then run:

```bash
kubectl port-forward \
  svc/<grafana-service-name> \
  3000:80 \
  -n monitoring
```

Open:

```text
http://localhost:3000
```

## 4. Public Application Access

The platform uses AWS Application Load Balancer (ALB) to expose Podinfo to the internet.

The AWS Load Balancer Controller manages the ALB based on the Kubernetes Ingress resource.

### 4.1. AWS Load Balancer Controller

The controller is installed using Helm.

It uses:

- IAM policy with the required AWS permissions
- IAM role
- EKS Pod Identity for AWS credentials

The IAM policy is based on the official AWS Load Balancer Controller policy.

### 4.2. Ingress Configuration

The Podinfo Ingress uses the following configuration:

| Setting | Value |
|---|---|
| Ingress Class | `alb` |
| Scheme | `internet-facing` |
| Target Type | `ip` |
| Listener | HTTP :80 |
| Health Check Path | `/healthz` |
| Host | Not configured |

The `ip` target type allows the ALB to route traffic directly to Pod IP addresses.

The ALB forwards requests to the Podinfo Service:

- Service type: `ClusterIP`
- Service port: `9898`

### 4.3. Domain and HTTPS

A custom domain has not been configured.

HTTPS with AWS Certificate Manager (ACM) is also pending.

To enable HTTPS:

1. Configure a domain.
2. Request an ACM certificate in the same AWS region as the ALB.
3. Validate the certificate.
4. Configure the domain DNS record to point to the ALB.
5. Update the Ingress to use HTTPS on port 443.
6. Verify HTTP and HTTPS access.

### 4.4. Health Checks

The ALB uses `/healthz` to check application target health.

This is an ALB target health check. It does not replace external uptime monitoring.

External health checks are not configured yet.

## 5. Troubleshooting

### 5.1. Terraform Initialization Fails

Possible causes:

- The S3 backend bucket does not exist.
- AWS credentials are missing or invalid.
- The user does not have permission to access the S3 bucket.

Useful commands:

```bash
aws sts get-caller-identity
aws s3 ls
terraform init
```

### 5.2. Terraform State Lock

If Terraform reports that the state is locked, check whether another Terraform operation is running.

Do not force-unlock unless you have confirmed that the lock is stale.

### 5.3. kubectl Cannot Connect to the Cluster

Possible causes:

- Incorrect kubeconfig context
- Invalid AWS credentials
- Current public IP is not allowed by the EKS API endpoint CIDR restriction

Useful commands:

```bash
aws sts get-caller-identity

aws eks update-kubeconfig \
  --region us-east-1 \
  --name <cluster-name>

kubectl get nodes
```

Check the configured EKS endpoint access CIDR if access is still denied.

### 5.4. ImagePullBackOff

Possible causes:

- Incorrect image name or tag
- Container registry is unavailable
- Missing registry credentials or permissions

Troubleshooting:

```bash
kubectl describe pod <pod-name> -n application
kubectl get events -n application
```

Verify the image reference and registry access.

### 5.5. CrashLoopBackOff

Possible causes:

- Application startup failure
- Incorrect environment variables
- Missing configuration
- Container resource limitations

Troubleshooting:

```bash
kubectl logs <pod-name> -n application

kubectl logs <pod-name> -n application --previous

kubectl describe pod <pod-name> -n application
```

Check application logs, events and container configuration.

### 5.6. Ingress Does Not Receive an ALB Address

Possible causes:

- AWS Load Balancer Controller is not running
- Missing IAM permissions
- Incorrect Ingress configuration
- Subnet discovery or tagging issues

Troubleshooting:

```bash
kubectl get ingress -n application

kubectl get pods -n kube-system

kubectl logs deployment/aws-load-balancer-controller \
  -n kube-system
```

Check controller logs, IAM configuration and subnet tags.

### 5.7. Metrics Are Missing in Grafana

Possible causes:

- Prometheus is not running
- Targets are not being scraped
- Incorrect Grafana data source configuration

Troubleshooting:

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Check Prometheus targets and Grafana data source settings.

### 5.8. Logs Are Missing in Loki

Possible causes:

- Grafana Alloy is not running
- Alloy cannot reach Loki
- Log collection configuration is incorrect

Troubleshooting:

```bash
kubectl get pods -n monitoring

kubectl logs daemonset/<alloy-daemonset-name> \
  -n monitoring
```

Check Alloy logs and Loki availability.

## 6. General Debugging Commands

Useful commands for investigating Kubernetes issues:

```bash
kubectl get pods -A

kubectl get events -A \
  --sort-by=.metadata.creationTimestamp

kubectl describe pod <pod-name> -n <namespace>

kubectl logs <pod-name> -n <namespace>

kubectl top nodes

kubectl top pods -A
```

These commands help identify workload failures, Kubernetes events and resource usage.

## 7. Current Status

The monitoring configuration includes Prometheus, Grafana, Loki, Alloy, dashboards and two alert rules.

The public access configuration includes AWS Load Balancer Controller and an internet-facing ALB Ingress.

The following items are still pending:

- Full deployment and runtime validation
- Real Slack notification integration
- Custom domain configuration
- HTTPS with ACM
- External uptime monitoring