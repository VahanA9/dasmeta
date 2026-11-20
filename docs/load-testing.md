# Performance Testing

## 1. Overview

The goal of performance testing is to evaluate how the Podinfo application behaves under different traffic levels.

Performance testing helps identify application performance limitations, measure response times, evaluate error rates, and understand how much traffic the application can handle.

Since performance testing has not yet been executed, this document describes the proposed testing approach, test scenarios, performance thresholds, monitoring strategy, and expected outcomes.

The proposed tests will be performed against the public AWS Application Load Balancer endpoint.

## 2. Testing Tool and Environment

### 2.1. Testing Tool

**Tool: k6**

k6 is an open-source load testing tool used to generate HTTP traffic and simulate concurrent virtual users.

It provides metrics such as:

- Requests per second (RPS)
- Average response time
- p50, p95, and p99 response times
- HTTP request failure rate
- Total requests and iterations

### 2.2. Test Environment

The test target will be the Podinfo application deployed on Amazon EKS.

**Target endpoint:**

```text
http://<application-endpoint>
```

The endpoint will be the public AWS Application Load Balancer DNS name.

### 2.3. Test Prerequisites

Before running performance tests, the following conditions should be verified:

- EKS cluster and worker nodes are operational.
- Podinfo application is deployed and available.
- AWS Load Balancer Controller is running.
- Application Ingress and ALB are configured correctly.
- The application responds successfully to HTTP requests.
- Prometheus and Grafana are operational.
- Kubernetes CPU and memory metrics are available.

## 3. Proposed Test Scenarios

The following test scenarios are proposed to evaluate application performance under different traffic levels.

| Scenario | Virtual Users | Duration | Purpose |
|---|---:|---:|---|
| Smoke Test | 1 | 1 minute | Verify application availability |
| Low Load | 10 | 2 minutes | Evaluate low traffic |
| Normal Load | 25 | 3 minutes | Simulate normal traffic |
| Medium Load | 50 | 3 minutes | Evaluate moderate traffic |
| High Load | 100 | 3 minutes | Evaluate higher traffic |
| Stress Test | Gradual increase | 5 minutes | Identify performance limitations |

Each scenario should be executed separately.

### 3.1. Smoke Test

**Configuration:**
- 1 virtual user
- 1 minute

Purpose:

Verify that the application is reachable and responds successfully before executing more intensive tests.

### 3.2. Low Load Test

**Configuration:**
- 10 virtual users
- 2 minutes

Purpose:

Evaluate application behavior under a relatively low traffic level.

### 3.3. Normal Load Test

**Configuration:**
- 25 virtual users
- 3 minutes

Purpose:

Evaluate application performance under normal simulated traffic.

### 3.4. Medium Load Test

**Configuration:**
- 50 virtual users
- 3 minutes

Purpose:

Observe response times, throughput, and resource utilization as concurrency increases.

### 3.5. High Load Test

**Configuration:**
- 100 virtual users
- 3 minutes

Purpose:

Evaluate application behavior under higher traffic and identify potential performance degradation.

### 3.6. Stress Test

**Configuration:**
- Gradually increase virtual users
- Total duration: 5 minutes

Purpose:

Identify the traffic level at which response times increase, errors appear, or application performance starts to degrade.

The virtual user count should increase gradually rather than immediately reaching the maximum load.

These test parameters are proposed values and may be adjusted based on the observed infrastructure capacity.

## 4. Proposed k6 Test Implementation

A k6 script will be used to generate HTTP requests against the Podinfo application.

Example test script:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL;

export const options = {
  vus: 10,
  duration: '2m',

  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const response = http.get(`${BASE_URL}/`);

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time below 1 second': (r) => r.timings.duration < 1000,
  });

  sleep(1);
}
```

This is an example configuration for the Low Load scenario. The virtual user count and duration should be adjusted for each test scenario.

### 4.1. Running the Tests

Install k6 on the machine used to generate test traffic.

Run the test script:

```bash
k6 run \
  -e BASE_URL=http://<application-endpoint> \
  load-testing/script.js
```

Each scenario should be executed separately.

The test parameters can be changed in the k6 script before running each scenario.

### 4.2. Stress Test Configuration

For the stress test, k6 can use a gradual load increase.

Example configuration:

```javascript
export const options = {
  stages: [
    { duration: '1m', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '1m', target: 75 },
    { duration: '1m', target: 100 },
    { duration: '1m', target: 100 },
  ],
};
```

This configuration gradually increases traffic and maintains the final load before the test finishes.

## 5. Performance Metrics and Thresholds

The following metrics will be collected and evaluated during testing.

### 5.1. Requests and Concurrency

Record:

- Number of virtual users
- Total HTTP requests
- Completed iterations
- Requests per second

### 5.2. Throughput (RPS)

Measure how many HTTP requests the application processes per second.

Observe whether throughput increases with concurrency or reaches a performance limit.

### 5.3. Response Time

Measure:

- Average response time
- p50 response time
- p95 response time
- p99 response time
- Maximum response time

p95 and p99 are particularly useful for identifying slow responses that may not be visible from average response time.

### 5.4. Error Rate

Measure the percentage of failed HTTP requests.

Monitor:

- HTTP 4xx responses
- HTTP 5xx responses
- Request timeouts
- Connection failures

### 5.5. Proposed Performance Thresholds

The following thresholds are proposed as initial performance objectives:

| Metric | Proposed Threshold |
|---|---:|
| p95 Response Time | Below 500 ms |
| p99 Response Time | Below 1000 ms |
| HTTP Request Failure Rate | Below 1% |
| Successful HTTP Requests | Above 99% |

These values are proposed targets, not measured performance results or guaranteed application capabilities.

They may be adjusted after baseline testing.

## 6. Infrastructure Monitoring During Tests

Performance testing should be performed together with infrastructure monitoring.

Prometheus and Grafana will be used to observe Kubernetes and application resource utilization.

### 6.1. CPU Utilization

Monitor CPU usage of:

- Podinfo application Pods
- Kubernetes worker nodes

Identify whether CPU utilization increases significantly as traffic grows.

### 6.2. Memory Utilization

Monitor memory consumption of application Pods and worker nodes.

Identify possible memory pressure or unexpected memory growth.

### 6.3. Kubernetes Pods

Monitor:

- Running Pod count
- Pod restarts
- Pod availability
- CPU and memory requests and limits
- Application replica count

### 6.4. Node Utilization

Monitor worker node CPU and memory utilization.

Identify whether the existing EKS worker nodes have sufficient capacity to handle the generated traffic.

### 6.5. Network and Application Metrics

Observe network traffic, HTTP request rates, response times, and application errors where metrics are available.

## 7. Possible Performance Improvements

Based on the results, the following improvements may be considered:

### 7.1. Resource Optimization

Adjust CPU and memory requests and limits according to observed resource consumption.

### 7.2. Application Scaling

Increase the number of Podinfo replicas if the application becomes resource-constrained.

### 7.3. Horizontal Pod Autoscaler

Configure Kubernetes Horizontal Pod Autoscaler (HPA) to automatically scale application replicas based on CPU or memory utilization.

### 7.4. Node Scaling

Increase EKS worker node capacity or configure node autoscaling if the existing nodes cannot handle the required workload.

### 7.5. Application Optimization

Investigate slow requests, high response times, and application errors to identify possible application-level bottlenecks.

All improvements should be based on actual observations rather than assumptions.

## 8. Test Execution and Results

**Current status: Not executed.**

The performance testing scenarios described in this document are proposed tests.

No actual performance results are reported at this stage.

After the infrastructure is deployed and the tests are executed, the following table will be completed with measured results.

| Scenario | VUs | RPS | Avg Response Time | p95 | Error Rate |
|---|---:|---:|---:|---:|---:|
| Smoke Test | Pending | Pending | Pending | Pending | Pending |
| Low Load | Pending | Pending | Pending | Pending | Pending |
| Normal Load | Pending | Pending | Pending | Pending | Pending |
| Medium Load | Pending | Pending | Pending | Pending | Pending |
| High Load | Pending | Pending | Pending | Pending | Pending |
| Stress Test | Pending | Pending | Pending | Pending | Pending |

### 8.1. Result Analysis

After executing the tests, results should be analyzed to determine:

- Maximum traffic handled without significant degradation.
- Response time behavior as concurrency increases.
- Error rate under different traffic levels.
- CPU and memory utilization during each scenario.
- Whether application or infrastructure scaling is required.
- Potential performance bottlenecks.

## 9. Conclusion

Performance testing is an important part of evaluating the reliability and scalability of the deployed application.

The proposed approach uses k6 to simulate different traffic levels and Prometheus/Grafana to monitor application and infrastructure performance.

The testing scenarios and thresholds provide an initial framework for evaluating the Podinfo application on Amazon EKS.

Since the tests have not yet been executed, all performance results remain pending.

Actual measurements and recommendations will be added after test execution.