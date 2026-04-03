# EKS Resilience Assessment Report

- **Cluster:** PetSite
- **Region:** ap-northeast-1
- **Date:** 2026-04-03T18:22:18Z

## Summary

| Total | PASS | FAIL | INFO |
|-------|------|------|------|
| 26 | 10 | 13 | 3 |

## Application Checks

| ID | Check | Severity | Status |
|----|-------|----------|--------|
| A1 | Avoid Running Singleton Pods | critical | ✅ PASS |
| A2 | Run Multiple Replicas | critical | ❌ FAIL |
| A3 | Use Pod Anti-Affinity | warning | ❌ FAIL |
| A4 | Use Liveness Probes | critical | ❌ FAIL |
| A5 | Use Readiness Probes | critical | ❌ FAIL |
| A6 | Use Pod Disruption Budgets | warning | ❌ FAIL |
| A7 | Run Kubernetes Metrics Server | warning | ✅ PASS |
| A8 | Use Horizontal Pod Autoscaler | warning | ❌ FAIL |
| A9 | Use Custom Metrics Scaling | info | ℹ️ INFO |
| A10 | Use Vertical Pod Autoscaler | info | ℹ️ INFO |
| A11 | Use PreStop Hooks | warning | ❌ FAIL |
| A12 | Use a Service Mesh | info | ℹ️ INFO |
| A13 | Monitor Your Applications | warning | ✅ PASS |
| A14 | Use Centralized Logging | warning | ✅ PASS |

## Control Plane Checks

| ID | Check | Severity | Status |
|----|-------|----------|--------|
| C1 | Monitor Control Plane Logs | warning | ❌ FAIL |
| C2 | Cluster Authentication | warning | ✅ PASS |
| C3 | Running Large Clusters | info | ✅ PASS |
| C4 | EKS Control Plane Endpoint Access Control | critical | ❌ FAIL |
| C5 | Avoid Catch-All Admission Webhooks | warning | ✅ PASS |

## Data Plane Checks

| ID | Check | Severity | Status |
|----|-------|----------|--------|
| D1 | Use Cluster Autoscaler or Karpenter | critical | ✅ PASS |
| D2 | Worker Nodes Spread Across Multiple AZs | critical | ✅ PASS |
| D3 | Configure Resource Requests/Limits | critical | ❌ FAIL |
| D4 | Namespace ResourceQuotas | warning | ❌ FAIL |
| D5 | Namespace LimitRanges | warning | ❌ FAIL |
| D6 | Monitor CoreDNS Metrics | warning | ✅ PASS |
| D7 | CoreDNS Configuration | info | ❌ FAIL |

## Failed Check Details

### A2: Run Multiple Replicas

**Findings:** {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","kind":"Deployment","replicas":1}; {"namespace":"chaos-mesh","name":"chaos-dashboard","kind":"Deployment","replicas":1}; {"namespace":"chaos-mesh","name":"chaos-dns-server","kind":"Deployment","replicas":1}; {"namespace":"deepflow","name":"prometheus-nfm","kind":"Deployment","replicas":1}; {"namespace":"deepflow","name":"yace-nfm","kind":"Deployment","replicas":1}; {"namespace":"petadoptions","name":"traffic-generator","kind":"Deployment","replicas":1}

**Remediation:** Set spec.replicas > 1 for all production workloads.

### A3: Use Pod Anti-Affinity

**Findings:** {"namespace":"chaos-mesh","name":"chaos-controller-manager","replicas":3}; {"namespace":"petadoptions","name":"list-adoptions","replicas":2}; {"namespace":"petadoptions","name":"pay-for-adoption","replicas":2}; {"namespace":"petadoptions","name":"pethistory-deployment","replicas":2}; {"namespace":"petadoptions","name":"petsite-deployment","replicas":2}; {"namespace":"petadoptions","name":"search-service","replicas":2}

**Remediation:** Add podAntiAffinity to spread replicas across nodes.

### A4: Use Liveness Probes

**Findings:** {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_probe":["manager"]}; {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_probe":["chaos-mesh"]}; {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_probe":["chaos-dashboard"]}; {"namespace":"deepflow","name":"prometheus-nfm","containers_missing_probe":["prometheus"]}; {"namespace":"deepflow","name":"yace-nfm","containers_missing_probe":["yace"]}; {"namespace":"petadoptions","name":"list-adoptions","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"pay-for-adoption","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"pethistory-deployment","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_probe":["petsite"]}; {"namespace":"petadoptions","name":"search-service","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"traffic-generator","containers_missing_probe":["traffic-generator"]}; {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent","containers_missing_probe":["otc-container"]}; {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows","containers_missing_probe":["otc-container"]}; {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows-container-insights","containers_missing_probe":["otc-container"]}; {"namespace":"amazon-cloudwatch","name":"dcgm-exporter","containers_missing_probe":["dcgm-exporter"]}; {"namespace":"amazon-cloudwatch","name":"fluent-bit","containers_missing_probe":["fluent-bit"]}; {"namespace":"amazon-cloudwatch","name":"fluent-bit-windows","containers_missing_probe":["fluent-bit"]}; {"namespace":"amazon-cloudwatch","name":"neuron-monitor","containers_missing_probe":["neuron-monitor"]}; {"namespace":"amazon-guardduty","name":"aws-guardduty-agent","containers_missing_probe":["aws-guardduty-agent"]}; {"namespace":"amazon-network-flow-monitor","name":"aws-network-flow-monitor-agent","containers_missing_probe":["aws-network-flow-monitor-agent"]}; {"namespace":"chaos-mesh","name":"chaos-daemon","containers_missing_probe":["chaos-daemon"]}; {"namespace":"deepflow","name":"deepflow-agent","containers_missing_probe":["deepflow-agent"]}; {"namespace":"default","name":"xray-daemon","containers_missing_probe":["xray-daemon"]}

**Remediation:** Add livenessProbe to every container in your workloads.

### A5: Use Readiness Probes

**Findings:** {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_probe":["manager"]}; {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_probe":["chaos-mesh"]}; {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_probe":["chaos-dashboard"]}; {"namespace":"deepflow","name":"prometheus-nfm","containers_missing_probe":["prometheus"]}; {"namespace":"deepflow","name":"yace-nfm","containers_missing_probe":["yace"]}; {"namespace":"petadoptions","name":"list-adoptions","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"pay-for-adoption","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"pethistory-deployment","containers_missing_probe":["pethistory","aws-otel-collector"]}; {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_probe":["petsite"]}; {"namespace":"petadoptions","name":"search-service","containers_missing_probe":["aws-otel-collector"]}; {"namespace":"petadoptions","name":"traffic-generator","containers_missing_probe":["traffic-generator"]}; {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent","containers_missing_probe":["otc-container"]}; {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows","containers_missing_probe":["otc-container"]}; {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows-container-insights","containers_missing_probe":["otc-container"]}; {"namespace":"amazon-cloudwatch","name":"dcgm-exporter","containers_missing_probe":["dcgm-exporter"]}; {"namespace":"amazon-cloudwatch","name":"fluent-bit","containers_missing_probe":["fluent-bit"]}; {"namespace":"amazon-cloudwatch","name":"fluent-bit-windows","containers_missing_probe":["fluent-bit"]}; {"namespace":"amazon-cloudwatch","name":"neuron-monitor","containers_missing_probe":["neuron-monitor"]}; {"namespace":"amazon-guardduty","name":"aws-guardduty-agent","containers_missing_probe":["aws-guardduty-agent"]}; {"namespace":"amazon-network-flow-monitor","name":"aws-network-flow-monitor-agent","containers_missing_probe":["aws-network-flow-monitor-agent"]}; {"namespace":"chaos-mesh","name":"chaos-daemon","containers_missing_probe":["chaos-daemon"]}; {"namespace":"deepflow","name":"deepflow-agent","containers_missing_probe":["deepflow-agent"]}; {"namespace":"default","name":"xray-daemon","containers_missing_probe":["xray-daemon"]}

**Remediation:** Add readinessProbe to every container in your workloads.

### A6: Use Pod Disruption Budgets

**Findings:** {"namespace":"chaos-mesh","name":"chaos-controller-manager","kind":"Deployment"}; {"namespace":"petadoptions","name":"list-adoptions","kind":"Deployment"}; {"namespace":"petadoptions","name":"pay-for-adoption","kind":"Deployment"}; {"namespace":"petadoptions","name":"pethistory-deployment","kind":"Deployment"}; {"namespace":"petadoptions","name":"petsite-deployment","kind":"Deployment"}; {"namespace":"petadoptions","name":"search-service","kind":"Deployment"}

**Remediation:** Create PodDisruptionBudgets for critical workloads.

### A8: Use Horizontal Pod Autoscaler

**Findings:** {"namespace":"chaos-mesh","name":"chaos-controller-manager"}

**Remediation:** Create HPA resources for multi-replica workloads.

### A11: Use PreStop Hooks

**Findings:** {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_hook":["manager"]}; {"namespace":"awesomeshop","name":"auth-service","containers_missing_hook":["auth-service"]}; {"namespace":"awesomeshop","name":"frontend","containers_missing_hook":["frontend"]}; {"namespace":"awesomeshop","name":"gateway-service","containers_missing_hook":["gateway-service"]}; {"namespace":"awesomeshop","name":"order-service","containers_missing_hook":["order-service"]}; {"namespace":"awesomeshop","name":"points-service","containers_missing_hook":["points-service"]}; {"namespace":"awesomeshop","name":"product-service","containers_missing_hook":["product-service"]}; {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_hook":["chaos-mesh"]}; {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_hook":["chaos-dashboard"]}; {"namespace":"chaos-mesh","name":"chaos-dns-server","containers_missing_hook":["chaos-dns-server"]}; {"namespace":"deepflow","name":"prometheus-nfm","containers_missing_hook":["prometheus"]}; {"namespace":"deepflow","name":"yace-nfm","containers_missing_hook":["yace"]}; {"namespace":"petadoptions","name":"list-adoptions","containers_missing_hook":["list-adoptions","aws-otel-collector"]}; {"namespace":"petadoptions","name":"pay-for-adoption","containers_missing_hook":["pay-for-adoption","aws-otel-collector"]}; {"namespace":"petadoptions","name":"pethistory-deployment","containers_missing_hook":["pethistory","aws-otel-collector"]}; {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_hook":["petsite"]}; {"namespace":"petadoptions","name":"search-service","containers_missing_hook":["search-service","aws-otel-collector"]}; {"namespace":"petadoptions","name":"traffic-generator","containers_missing_hook":["traffic-generator"]}

**Remediation:** Add lifecycle.preStop hooks for graceful termination.

### C1: Monitor Control Plane Logs

**Findings:** API server logging not enabled

**Remediation:** Enable at least api log type via aws eks update-cluster-config.

### C4: EKS Control Plane Endpoint Access Control

**Findings:** Public endpoint open to 0.0.0.0/0

**Remediation:** Restrict public endpoint access or use a fully private endpoint.

### D3: Configure Resource Requests/Limits

**Findings:** {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_resources":[{"name":"manager","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}; {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_resources":[{"name":"chaos-mesh","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}; {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_resources":[{"name":"chaos-dashboard","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}; {"namespace":"chaos-mesh","name":"chaos-dns-server","containers_missing_resources":[{"name":"chaos-dns-server","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}; {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_resources":[{"name":"petsite","has_cpu_request":false,"has_cpu_limit":false,"has_mem_request":false,"has_mem_limit":false}]}

**Remediation:** Set CPU/memory requests and limits for all containers.

### D4: Namespace ResourceQuotas

**Findings:** amazon-cloudwatch; amazon-guardduty; amazon-network-flow-monitor; awesomeshop; chaos-mesh; deepflow; default; node-configuration-daemonset; petadoptions

**Remediation:** Create ResourceQuota in each namespace to enforce resource limits.

### D5: Namespace LimitRanges

**Findings:** amazon-cloudwatch; amazon-guardduty; amazon-network-flow-monitor; awesomeshop; chaos-mesh; deepflow; default; node-configuration-daemonset; petadoptions

**Remediation:** Create LimitRange in each namespace to set default resource constraints.

### D7: CoreDNS Configuration

**Findings:** CoreDNS is self-managed — consider using EKS managed add-on

**Remediation:** Use EKS managed add-on for CoreDNS to get automatic updates.

