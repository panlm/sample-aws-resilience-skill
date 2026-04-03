#!/usr/bin/env bash
# Auto-generated remediation script from EKS Resilience Assessment
# Cluster: PetSite | Date: 2026-04-03T18:22:20Z
# WARNING: Review each command before executing!
set -euo pipefail

CLUSTER_NAME="PetSite"
REGION="ap-northeast-1"

echo "=== A2: Run Multiple Replicas ==="
echo "Found: {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","kind":"Deployment","replicas":1}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dashboard","kind":"Deployment","replicas":1}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dns-server","kind":"Deployment","replicas":1}"
echo "Found: {"namespace":"deepflow","name":"prometheus-nfm","kind":"Deployment","replicas":1}"
echo "Found: {"namespace":"deepflow","name":"yace-nfm","kind":"Deployment","replicas":1}"
echo "Found: {"namespace":"petadoptions","name":"traffic-generator","kind":"Deployment","replicas":1}"
kubectl scale deployment amazon-cloudwatch-observability-controller-manager --replicas=2 -n amazon-cloudwatch
kubectl scale deployment chaos-dashboard --replicas=2 -n chaos-mesh
kubectl scale deployment chaos-dns-server --replicas=2 -n chaos-mesh
kubectl scale deployment prometheus-nfm --replicas=2 -n deepflow
kubectl scale deployment yace-nfm --replicas=2 -n deepflow
kubectl scale deployment traffic-generator --replicas=2 -n petadoptions

echo "=== A3: Use Pod Anti-Affinity ==="
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager","replicas":3}"
echo "Found: {"namespace":"petadoptions","name":"list-adoptions","replicas":2}"
echo "Found: {"namespace":"petadoptions","name":"pay-for-adoption","replicas":2}"
echo "Found: {"namespace":"petadoptions","name":"pethistory-deployment","replicas":2}"
echo "Found: {"namespace":"petadoptions","name":"petsite-deployment","replicas":2}"
echo "Found: {"namespace":"petadoptions","name":"search-service","replicas":2}"
kubectl patch deployment chaos-controller-manager -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["chaos-controller-manager"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'
kubectl patch deployment list-adoptions -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["list-adoptions"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'
kubectl patch deployment pay-for-adoption -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["pay-for-adoption"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'
kubectl patch deployment pethistory-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["pethistory-deployment"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'
kubectl patch deployment petsite-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["petsite-deployment"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'
kubectl patch deployment search-service -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["search-service"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'

echo "=== A4: Use Liveness Probes ==="
echo "Found: {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_probe":["manager"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_probe":["chaos-mesh"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_probe":["chaos-dashboard"]}"
echo "Found: {"namespace":"deepflow","name":"prometheus-nfm","containers_missing_probe":["prometheus"]}"
echo "Found: {"namespace":"deepflow","name":"yace-nfm","containers_missing_probe":["yace"]}"
echo "Found: {"namespace":"petadoptions","name":"list-adoptions","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"pay-for-adoption","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"pethistory-deployment","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_probe":["petsite"]}"
echo "Found: {"namespace":"petadoptions","name":"search-service","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"traffic-generator","containers_missing_probe":["traffic-generator"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent","containers_missing_probe":["otc-container"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows","containers_missing_probe":["otc-container"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows-container-insights","containers_missing_probe":["otc-container"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"dcgm-exporter","containers_missing_probe":["dcgm-exporter"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"fluent-bit","containers_missing_probe":["fluent-bit"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"fluent-bit-windows","containers_missing_probe":["fluent-bit"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"neuron-monitor","containers_missing_probe":["neuron-monitor"]}"
echo "Found: {"namespace":"amazon-guardduty","name":"aws-guardduty-agent","containers_missing_probe":["aws-guardduty-agent"]}"
echo "Found: {"namespace":"amazon-network-flow-monitor","name":"aws-network-flow-monitor-agent","containers_missing_probe":["aws-network-flow-monitor-agent"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-daemon","containers_missing_probe":["chaos-daemon"]}"
echo "Found: {"namespace":"deepflow","name":"deepflow-agent","containers_missing_probe":["deepflow-agent"]}"
echo "Found: {"namespace":"default","name":"xray-daemon","containers_missing_probe":["xray-daemon"]}"
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment amazon-cloudwatch-observability-controller-manager -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment chaos-controller-manager -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment chaos-dashboard -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment prometheus-nfm -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment yace-nfm -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment list-adoptions -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment pay-for-adoption -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment pethistory-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment petsite-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment search-service -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment traffic-generator -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment cloudwatch-agent -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment cloudwatch-agent-windows -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment cloudwatch-agent-windows-container-insights -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment dcgm-exporter -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment fluent-bit -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment fluent-bit-windows -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment neuron-monitor -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment aws-guardduty-agent -n amazon-guardduty --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment aws-network-flow-monitor-agent -n amazon-network-flow-monitor --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment chaos-daemon -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment deepflow-agent -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'
# Add liveness probes — adjust path/port for your application:
# kubectl patch deployment xray-daemon -n default --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":15,"periodSeconds":10,"timeoutSeconds":5,"failureThreshold":3}}]}}}}'

echo "=== A5: Use Readiness Probes ==="
echo "Found: {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_probe":["manager"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_probe":["chaos-mesh"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_probe":["chaos-dashboard"]}"
echo "Found: {"namespace":"deepflow","name":"prometheus-nfm","containers_missing_probe":["prometheus"]}"
echo "Found: {"namespace":"deepflow","name":"yace-nfm","containers_missing_probe":["yace"]}"
echo "Found: {"namespace":"petadoptions","name":"list-adoptions","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"pay-for-adoption","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"pethistory-deployment","containers_missing_probe":["pethistory","aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_probe":["petsite"]}"
echo "Found: {"namespace":"petadoptions","name":"search-service","containers_missing_probe":["aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"traffic-generator","containers_missing_probe":["traffic-generator"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent","containers_missing_probe":["otc-container"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows","containers_missing_probe":["otc-container"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"cloudwatch-agent-windows-container-insights","containers_missing_probe":["otc-container"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"dcgm-exporter","containers_missing_probe":["dcgm-exporter"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"fluent-bit","containers_missing_probe":["fluent-bit"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"fluent-bit-windows","containers_missing_probe":["fluent-bit"]}"
echo "Found: {"namespace":"amazon-cloudwatch","name":"neuron-monitor","containers_missing_probe":["neuron-monitor"]}"
echo "Found: {"namespace":"amazon-guardduty","name":"aws-guardduty-agent","containers_missing_probe":["aws-guardduty-agent"]}"
echo "Found: {"namespace":"amazon-network-flow-monitor","name":"aws-network-flow-monitor-agent","containers_missing_probe":["aws-network-flow-monitor-agent"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-daemon","containers_missing_probe":["chaos-daemon"]}"
echo "Found: {"namespace":"deepflow","name":"deepflow-agent","containers_missing_probe":["deepflow-agent"]}"
echo "Found: {"namespace":"default","name":"xray-daemon","containers_missing_probe":["xray-daemon"]}"
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment amazon-cloudwatch-observability-controller-manager -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment chaos-controller-manager -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment chaos-dashboard -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment prometheus-nfm -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment yace-nfm -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment list-adoptions -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment pay-for-adoption -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment pethistory-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment petsite-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment search-service -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment traffic-generator -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment cloudwatch-agent -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment cloudwatch-agent-windows -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment cloudwatch-agent-windows-container-insights -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment dcgm-exporter -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment fluent-bit -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment fluent-bit-windows -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment neuron-monitor -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment aws-guardduty-agent -n amazon-guardduty --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment aws-network-flow-monitor-agent -n amazon-network-flow-monitor --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment chaos-daemon -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment deepflow-agent -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'
# Add readiness probes — adjust path/port for your application:
# kubectl patch deployment xray-daemon -n default --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":3,"failureThreshold":3}}]}}}}'

echo "=== A6: Use Pod Disruption Budgets ==="
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager","kind":"Deployment"}"
echo "Found: {"namespace":"petadoptions","name":"list-adoptions","kind":"Deployment"}"
echo "Found: {"namespace":"petadoptions","name":"pay-for-adoption","kind":"Deployment"}"
echo "Found: {"namespace":"petadoptions","name":"pethistory-deployment","kind":"Deployment"}"
echo "Found: {"namespace":"petadoptions","name":"petsite-deployment","kind":"Deployment"}"
echo "Found: {"namespace":"petadoptions","name":"search-service","kind":"Deployment"}"
cat <<PDBEOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: chaos-controller-manager-pdb
  namespace: chaos-mesh
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: chaos-controller-manager
PDBEOF
cat <<PDBEOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: list-adoptions-pdb
  namespace: petadoptions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: list-adoptions
PDBEOF
cat <<PDBEOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pay-for-adoption-pdb
  namespace: petadoptions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: pay-for-adoption
PDBEOF
cat <<PDBEOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pethistory-deployment-pdb
  namespace: petadoptions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: pethistory-deployment
PDBEOF
cat <<PDBEOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: petsite-deployment-pdb
  namespace: petadoptions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: petsite-deployment
PDBEOF
cat <<PDBEOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: search-service-pdb
  namespace: petadoptions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: search-service
PDBEOF

echo "=== A8: Use Horizontal Pod Autoscaler ==="
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager"}"
kubectl autoscale deployment chaos-controller-manager -n chaos-mesh --min=2 --max=10 --cpu-percent=70

echo "=== A11: Use PreStop Hooks ==="
echo "Found: {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_hook":["manager"]}"
echo "Found: {"namespace":"awesomeshop","name":"auth-service","containers_missing_hook":["auth-service"]}"
echo "Found: {"namespace":"awesomeshop","name":"frontend","containers_missing_hook":["frontend"]}"
echo "Found: {"namespace":"awesomeshop","name":"gateway-service","containers_missing_hook":["gateway-service"]}"
echo "Found: {"namespace":"awesomeshop","name":"order-service","containers_missing_hook":["order-service"]}"
echo "Found: {"namespace":"awesomeshop","name":"points-service","containers_missing_hook":["points-service"]}"
echo "Found: {"namespace":"awesomeshop","name":"product-service","containers_missing_hook":["product-service"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_hook":["chaos-mesh"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_hook":["chaos-dashboard"]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dns-server","containers_missing_hook":["chaos-dns-server"]}"
echo "Found: {"namespace":"deepflow","name":"prometheus-nfm","containers_missing_hook":["prometheus"]}"
echo "Found: {"namespace":"deepflow","name":"yace-nfm","containers_missing_hook":["yace"]}"
echo "Found: {"namespace":"petadoptions","name":"list-adoptions","containers_missing_hook":["list-adoptions","aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"pay-for-adoption","containers_missing_hook":["pay-for-adoption","aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"pethistory-deployment","containers_missing_hook":["pethistory","aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_hook":["petsite"]}"
echo "Found: {"namespace":"petadoptions","name":"search-service","containers_missing_hook":["search-service","aws-otel-collector"]}"
echo "Found: {"namespace":"petadoptions","name":"traffic-generator","containers_missing_hook":["traffic-generator"]}"
# Add preStop hook for graceful termination:
# kubectl patch deployment amazon-cloudwatch-observability-controller-manager -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment auth-service -n awesomeshop --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment frontend -n awesomeshop --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment gateway-service -n awesomeshop --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment order-service -n awesomeshop --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment points-service -n awesomeshop --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment product-service -n awesomeshop --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment chaos-controller-manager -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment chaos-dashboard -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment chaos-dns-server -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment prometheus-nfm -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment yace-nfm -n deepflow --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment list-adoptions -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment pay-for-adoption -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment pethistory-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment petsite-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment search-service -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'
# Add preStop hook for graceful termination:
# kubectl patch deployment traffic-generator -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","lifecycle":{"preStop":{"exec":{"command":["/bin/sh","-c","sleep 10"]}}}}]}}}}'

echo "=== C1: Monitor Control Plane Logs ==="
echo "Found: API server logging not enabled"
aws eks update-cluster-config --name "$CLUSTER_NAME" --region "$REGION"   --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'

echo "=== C4: EKS Control Plane Endpoint Access Control ==="
echo "Found: Public endpoint open to 0.0.0.0/0"
# Restrict public endpoint — option A: private only
aws eks update-cluster-config --name "$CLUSTER_NAME" --region "$REGION"   --resources-vpc-config endpointPublicAccess=false,endpointPrivateAccess=true
# Option B: restrict CIDR (replace YOUR_CIDR):
# aws eks update-cluster-config --name "$CLUSTER_NAME" --region "$REGION" #   --resources-vpc-config endpointPublicAccess=true,endpointPrivateAccess=true,publicAccessCidrs="YOUR_CIDR/32"

echo "=== D3: Configure Resource Requests/Limits ==="
echo "Found: {"namespace":"amazon-cloudwatch","name":"amazon-cloudwatch-observability-controller-manager","containers_missing_resources":[{"name":"manager","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-controller-manager","containers_missing_resources":[{"name":"chaos-mesh","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dashboard","containers_missing_resources":[{"name":"chaos-dashboard","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}"
echo "Found: {"namespace":"chaos-mesh","name":"chaos-dns-server","containers_missing_resources":[{"name":"chaos-dns-server","has_cpu_request":true,"has_cpu_limit":false,"has_mem_request":true,"has_mem_limit":false}]}"
echo "Found: {"namespace":"petadoptions","name":"petsite-deployment","containers_missing_resources":[{"name":"petsite","has_cpu_request":false,"has_cpu_limit":false,"has_mem_request":false,"has_mem_limit":false}]}"
# Set resource requests/limits — adjust values for your workload:
# kubectl patch deployment amazon-cloudwatch-observability-controller-manager -n amazon-cloudwatch --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
# Set resource requests/limits — adjust values for your workload:
# kubectl patch deployment chaos-controller-manager -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
# Set resource requests/limits — adjust values for your workload:
# kubectl patch deployment chaos-dashboard -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
# Set resource requests/limits — adjust values for your workload:
# kubectl patch deployment chaos-dns-server -n chaos-mesh --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
# Set resource requests/limits — adjust values for your workload:
# kubectl patch deployment petsite-deployment -n petadoptions --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'

echo "=== D4: Namespace ResourceQuotas ==="
echo "Found: amazon-cloudwatch"
echo "Found: amazon-guardduty"
echo "Found: amazon-network-flow-monitor"
echo "Found: awesomeshop"
echo "Found: chaos-mesh"
echo "Found: deepflow"
echo "Found: default"
echo "Found: node-configuration-daemonset"
echo "Found: petadoptions"
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: amazon-cloudwatch
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: amazon-guardduty
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: amazon-network-flow-monitor
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: awesomeshop
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: chaos-mesh
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: deepflow
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: default
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: node-configuration-daemonset
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF
cat <<RQEOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: petadoptions
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
RQEOF

echo "=== D5: Namespace LimitRanges ==="
echo "Found: amazon-cloudwatch"
echo "Found: amazon-guardduty"
echo "Found: amazon-network-flow-monitor"
echo "Found: awesomeshop"
echo "Found: chaos-mesh"
echo "Found: deepflow"
echo "Found: default"
echo "Found: node-configuration-daemonset"
echo "Found: petadoptions"
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: amazon-cloudwatch
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: amazon-guardduty
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: amazon-network-flow-monitor
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: awesomeshop
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: chaos-mesh
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: deepflow
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: default
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: node-configuration-daemonset
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF
cat <<LREOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: petadoptions
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
LREOF

echo "=== D7: CoreDNS Configuration ==="
echo "Found: CoreDNS is self-managed — consider using EKS managed add-on"
