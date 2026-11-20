# AWS EKS Platform

## Overview

This project demonstrates infrastructure provisioning and application deployment on AWS using Amazon EKS.

Terraform manages AWS infrastructure, while Helm manages Kubernetes applications and platform services.

The project focuses on infrastructure automation, application deployment, monitoring, logging, public access and performance testing.

## Technology Stack

| Category | Technology |
|---|---|
| Cloud Provider | AWS |
| Infrastructure as Code | Terraform |
| Container Orchestration | Amazon EKS |
| Package Management | Helm |
| Demo Application | Podinfo |
| Metrics Collection | Prometheus |
| Dashboards and Alerting | Grafana |
| Log Collection | Grafana Alloy |
| Log Storage | Loki |
| Load Balancing | AWS Load Balancer Controller |
| Performance Testing | Grafana k6 |

## Architecture Overview

- Terraform provisions the AWS VPC and EKS infrastructure.
- Amazon EKS provides the Kubernetes environment.
- Helm manages application and monitoring deployments.
- Podinfo is deployed as the demo application.
- Prometheus collects infrastructure and application metrics.
- Grafana provides dashboards and alerting.
- Grafana Alloy collects Kubernetes logs and forwards them to Loki.
- AWS Load Balancer Controller exposes Podinfo through an internet-facing Application Load Balancer.

## Project Structure

```text
.
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── operations.md
│   └── load-testing.md
├── helm/
│   └── charts/
│       └── podinfo/
├── terraform/
│   ├── infrastructure/
│   │   ├── modules/
│   │   │   ├── eks/
│   │   │   └── vpc/
│   │   └── ...
│   └── platform/
│       └── helm/
│           ├── monitoring/
│           ├── podinfo/
│           └── storageclass/
└── README.md
```

## Main Components

### Infrastructure

- AWS VPC with public and private subnets.
- Amazon EKS cluster.
- Managed node group using Spot instances.
- IAM roles and EKS Pod Identity.
- Terraform remote state stored in Amazon S3.
- Separate Terraform states for infrastructure and platform.

### Application

- Podinfo deployed using Helm.
- Two application replicas.
- Kubernetes ClusterIP Service.
- Ingress configuration for public access through ALB.

### Monitoring and Logging

- Prometheus collects infrastructure and application metrics.
- Grafana provides dashboards and alerting.
- Loki stores application and Kubernetes logs.
- Grafana Alloy collects and forwards logs.
- Dashboards and alert rules are provisioned through Helm.

### Configured Alerts

| Alert | Condition | Duration |
|---|---|---|
| High CPU Usage | CPU usage above 80% | 5 minutes |
| High Memory Usage | Memory usage above 85% | 5 minutes |

A Slack contact point and notification policy are included as examples. A real Slack webhook has not been configured, so notifications are not currently delivered to Slack.

### Public Access

AWS Load Balancer Controller exposes the application through an internet-facing Application Load Balancer.

Custom domain, HTTPS and external health checks are still pending.

## Prerequisites

Required tools:

- AWS CLI
- Terraform (>= 1.5.7)
- kubectl
- Helm
- Git

An AWS account with the required permissions is also needed.

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | AWS infrastructure, EKS architecture and Terraform structure |
| [Deployment](docs/deployment.md) | Prerequisites, infrastructure and platform deployment, verification and cleanup |
| [Operations](docs/operations.md) | Monitoring, logging, alerting, public access and troubleshooting |
| [Load Testing](docs/load-testing.md) | k6 test scenarios, execution instructions and performance results |

## Load Testing

Performance testing is planned using Grafana k6.

Planned scenarios include smoke, load and stress testing.

The tests will measure:

- Request throughput (RPS).
- Concurrent virtual users.
- Response time (average, p95 and p99).
- Error rate.
- Application behavior under increasing load.

Test execution, actual results and observations will be documented in `docs/load-testing.md` after the tests are performed.

## Project Status

Infrastructure and application configurations have been prepared for deployment and validation.

Pending tasks:

- Full infrastructure and application runtime validation.
- Performance and load testing.
- Custom domain configuration.
- HTTPS configuration.
- External health checks.
- Real Slack webhook integration.

## Notes

This project is intended for learning, demonstration and technical evaluation.

AWS resources may generate costs while running. Review the infrastructure configuration and estimated costs before deployment.