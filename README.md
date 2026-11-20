# AWS EKS Platform

## Overview

This project demonstrates how to deploy and manage a containerized application on AWS using Amazon EKS.

Infrastructure is provisioned with Terraform, while Kubernetes applications and supporting services are managed with Helm.

The main focus is infrastructure automation, application deployment, monitoring, logging, and public access.

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

The platform uses AWS infrastructure to run a Kubernetes cluster with a demo application and monitoring stack.

- Terraform manages AWS infrastructure, including VPC and EKS.
- Amazon EKS provides the Kubernetes environment.
- Helm manages application and monitoring deployments.
- Podinfo is used as the demo application.
- Prometheus collects metrics from the cluster and application.
- Grafana provides dashboards and alerting.
- Grafana Alloy collects Kubernetes logs and forwards them to Loki.
- AWS Load Balancer Controller provides public application access through an Application Load Balancer.

## Project Structure

```text
.
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── operations.md
│   └── load-testing.md
├── helm/
│   ├── charts/
│   │   └── podinfo/
│   ├── monitoring/
│   │   ├── dashboards/
│   │   ├── alerting/
│   │   └── templates/
│   └── podinfo/
├── kubernetes/
├── load-testing/
├── terraform/
│   └── modules/
│       ├── eks/
│       └── vpc/
└── README.md
```

## Main Components

### Infrastructure

- AWS VPC with public and private subnets.
- Amazon EKS cluster.
- Managed node group using Spot instances.
- IAM roles and EKS Pod Identity.
- Terraform remote state stored in Amazon S3.

### Application

- Podinfo deployed with Helm.
- Two application replicas.
- Kubernetes Service for internal communication.
- Ingress configuration for public access.

### Monitoring and Logging

- Prometheus collects infrastructure and application metrics.
- Grafana provides dashboards and alerting.
- Loki stores application and Kubernetes logs.
- Grafana Alloy collects and forwards logs.
- Kubernetes and application dashboards are provisioned through Helm.

### Configured Alerts

The following alert rules are configured in Grafana:

| Alert | Condition | Duration |
|---|---|---|
| High CPU Usage | CPU usage above 80% | 5 minutes |
| High Memory Usage | Memory usage above 85% | 5 minutes |

A Slack contact point and notification policy are configured as examples. A real Slack webhook has not been added yet, so notifications are not currently delivered to Slack.

### Public Access

AWS Load Balancer Controller is configured to expose the application through an internet-facing Application Load Balancer.

Custom domain, HTTPS configuration, and external health checks are still pending.

## Prerequisites

The following tools are required to work with the project:

- AWS CLI
- Terraform
- kubectl
- Helm
- Git

An AWS account with the required permissions is also needed.

## Documentation

Detailed setup, architecture, and operational instructions are available in the `docs/` directory.

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | AWS infrastructure, VPC, EKS, Kubernetes components, and Terraform architecture |
| [Deployment](docs/deployment.md) | Prerequisites, AWS configuration, deployment steps, and cleanup |
| [Operations](docs/operations.md) | Monitoring, logging, alerting, public access, and troubleshooting |
| [Load Testing](docs/load-testing.md) | Planned k6 test scenarios, execution instructions, and test results |

## Load Testing

Performance testing is planned using Grafana k6.

The planned test scenarios include different load levels, from smoke testing to stress testing.

The tests will measure:

- Request throughput (RPS)
- Concurrent virtual users
- Response time (average, p95, and p99)
- Error rate
- Application behavior under increasing load

Test execution, actual results, and observations will be documented after the tests are performed.

## Project Status

Infrastructure and application configurations have been prepared for deployment and validation.

The following tasks are still pending:

- Infrastructure and application deployment validation.
- Performance and load testing.
- Custom domain configuration.
- HTTPS configuration.
- External health checks.
- Real Slack webhook integration.

## Notes

This project is intended for learning, demonstration, and technical evaluation.

AWS resources may generate costs while running. Review the infrastructure configuration and estimated costs before deployment.