# Load Testing

## 1. Overview

The goal is to evaluate Podinfo performance under different traffic levels using **Grafana k6**.

Tests will target the public AWS Application Load Balancer endpoint.

## 2. Prerequisites

Before testing, verify:
- EKS cluster and Podinfo are running.
- ALB endpoint is accessible.
- Prometheus and Grafana are operational.

## 3. Test Scenarios

| Scenario | Virtual Users | Duration |
|---|---:|---:|
| Smoke | 1 | 1 minute |
| Low Load | 10 | 2 minutes |
| Normal Load | 25 | 3 minutes |
| Medium Load | 50 | 3 minutes |
| High Load | 100 | 3 minutes |
| Stress | Gradually increase to 100 | 5 minutes |

Run scenarios separately.

## 4. Monitoring

During testing, use Grafana and Prometheus to monitor:

- CPU and memory usage of Pods and worker nodes.
- Pod restarts and availability.
- Request rate and response time.
- HTTP errors.

## 5. Performance Criteria

Initial target thresholds:

| Metric | Target |
|---|---:|
| p95 Response Time | Below 500 ms |
| HTTP Error Rate | Below 1% |

These are proposed targets, not measured results.