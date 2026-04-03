#!/usr/bin/env bash
set -euo pipefail

# EKS Resilience Assessment — 28 best-practice checks
# Outputs: assessment.json + assessment-report.md

###############################################################################
# Globals
###############################################################################
CLUSTER_NAME=""
REGION=""
NAMESPACES=""
OUTPUT_DIR="./output"
SKIP_NS_REGEX="^(kube-system|kube-public|kube-node-lease)$"
RESULTS=()
TOTAL=0; PASS=0; FAIL=0; INFO=0

###############################################################################
# Helpers
###############################################################################
usage() {
  cat <<'USAGE'
Usage: assess.sh [OPTIONS]

Options:
  --cluster NAME        EKS cluster name (auto-detected if omitted)
  --region REGION        AWS region (default: from AWS_DEFAULT_REGION or aws configure)
  --namespaces "a,b,c"  Comma-separated namespaces to check (default: all non-system)
  --output-dir DIR       Output directory (default: ./output)
  -h, --help             Show this help
USAGE
  exit 0
}

log()  { echo "[assess] $*" >&2; }
die()  { echo "[assess] ERROR: $*" >&2; exit 1; }

check_deps() {
  for cmd in kubectl aws jq; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
  done
}

discover_cluster() {
  if [[ -z "$CLUSTER_NAME" ]]; then
    CLUSTER_NAME=$(kubectl config current-context 2>/dev/null | sed 's|.*:cluster/||' || true)
    [[ -n "$CLUSTER_NAME" ]] || die "Cannot auto-detect cluster name. Use --cluster."
    log "Auto-detected cluster: $CLUSTER_NAME"
  fi
  if [[ -z "$REGION" ]]; then
    REGION=$(aws configure get region 2>/dev/null || echo "")
    [[ -n "$REGION" ]] || REGION="ap-northeast-1"
    log "Using region: $REGION"
  fi
}

get_namespaces() {
  if [[ -n "$NAMESPACES" ]]; then
    NS_LIST=$(echo "$NAMESPACES" | tr ',' '\n')
  else
    NS_LIST=$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)
  fi
  # Filter out system namespaces
  FILTERED_NS=()
  while IFS= read -r ns; do
    [[ -z "$ns" ]] && continue
    if ! echo "$ns" | grep -qE "$SKIP_NS_REGEX"; then
      FILTERED_NS+=("$ns")
    fi
  done <<< "$NS_LIST"
  log "Target namespaces (${#FILTERED_NS[@]}): ${FILTERED_NS[*]}"
}

# emit_result ID NAME CATEGORY SEVERITY STATUS FINDINGS_JSON RESOURCES_JSON REMEDIATION
emit_result() {
  local id="$1" name="$2" category="$3" severity="$4" status="$5"
  local findings="$6" resources="$7" remediation="$8"
  local json
  json=$(jq -nc \
    --arg id "$id" \
    --arg name "$name" \
    --arg category "$category" \
    --arg severity "$severity" \
    --arg status "$status" \
    --argjson findings "$findings" \
    --argjson resources "$resources" \
    --arg remediation "$remediation" \
    '{id:$id, name:$name, category:$category, severity:$severity, status:$status, findings:$findings, resources_affected:$resources, remediation:$remediation}')
  echo "$json"
  RESULTS+=("$json")
  TOTAL=$((TOTAL + 1))
  case "$status" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    *)    INFO=$((INFO + 1)) ;;
  esac
}

# Safe kubectl wrapper — returns empty JSON array on failure
kube_json() {
  kubectl "$@" -o json 2>/dev/null || echo '{"items":[]}'
}

###############################################################################
# Application Checks A1–A14
###############################################################################

check_a1() {
  log "A1: Singleton Pods"
  local raw found status
  raw=$(kube_json get pods --all-namespaces)
  found=$(echo "$raw" | jq '[.items[] | select((.metadata.ownerReferences // []) | length == 0) | select(.metadata.namespace | test("^kube-") | not) | {namespace:.metadata.namespace, name:.metadata.name}]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A1" "Avoid Running Singleton Pods" "application" "critical" "$status" \
    "$found" "$found" "Wrap standalone pods in a Deployment, StatefulSet, or Job controller."
}

check_a2() {
  log "A2: Multiple Replicas"
  local deps sts found status
  deps=$(kube_json get deployments --all-namespaces)
  sts=$(kube_json get statefulsets --all-namespaces)
  found=$(jq -nc --argjson d "$deps" --argjson s "$sts" '
    [$d.items[] | select(.metadata.namespace | test("^kube-") | not) | select(.spec.replicas == 1) | {namespace:.metadata.namespace, name:.metadata.name, kind:"Deployment", replicas:.spec.replicas}] +
    [$s.items[] | select(.metadata.namespace | test("^kube-") | not) | select(.spec.replicas == 1) | {namespace:.metadata.namespace, name:.metadata.name, kind:"StatefulSet", replicas:.spec.replicas}]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A2" "Run Multiple Replicas" "application" "critical" "$status" \
    "$found" "$found" "Set spec.replicas > 1 for all production workloads."
}

check_a3() {
  log "A3: Pod Anti-Affinity"
  local deps found status
  deps=$(kube_json get deployments --all-namespaces)
  found=$(echo "$deps" | jq '[.items[] | select(.metadata.namespace | test("^kube-") | not) | select(.spec.replicas > 1) | select(.spec.template.spec.affinity.podAntiAffinity == null) | {namespace:.metadata.namespace, name:.metadata.name, replicas:.spec.replicas}]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A3" "Use Pod Anti-Affinity" "application" "warning" "$status" \
    "$found" "$found" "Add podAntiAffinity to spread replicas across nodes."
}

check_a4() {
  log "A4: Liveness Probes"
  local deps sts ds found status
  deps=$(kube_json get deployments --all-namespaces)
  sts=$(kube_json get statefulsets --all-namespaces)
  ds=$(kube_json get daemonsets --all-namespaces)
  found=$(jq -nc --argjson d "$deps" --argjson s "$sts" --argjson a "$ds" '
    [($d.items[], $s.items[], $a.items[]) | select(.metadata.namespace | test("^kube-") | not) |
     {namespace:.metadata.namespace, name:.metadata.name, containers_missing_probe:
       [.spec.template.spec.containers[] | select(.livenessProbe == null) | .name]}
     | select(.containers_missing_probe | length > 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A4" "Use Liveness Probes" "application" "critical" "$status" \
    "$found" "$found" "Add livenessProbe to every container in your workloads."
}

check_a5() {
  log "A5: Readiness Probes"
  local deps sts ds found status
  deps=$(kube_json get deployments --all-namespaces)
  sts=$(kube_json get statefulsets --all-namespaces)
  ds=$(kube_json get daemonsets --all-namespaces)
  found=$(jq -nc --argjson d "$deps" --argjson s "$sts" --argjson a "$ds" '
    [($d.items[], $s.items[], $a.items[]) | select(.metadata.namespace | test("^kube-") | not) |
     {namespace:.metadata.namespace, name:.metadata.name, containers_missing_probe:
       [.spec.template.spec.containers[] | select(.readinessProbe == null) | .name]}
     | select(.containers_missing_probe | length > 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A5" "Use Readiness Probes" "application" "critical" "$status" \
    "$found" "$found" "Add readinessProbe to every container in your workloads."
}

check_a6() {
  log "A6: Pod Disruption Budgets"
  local deps sts pdbs found status
  deps=$(kube_json get deployments --all-namespaces)
  sts=$(kube_json get statefulsets --all-namespaces)
  pdbs=$(kubectl get pdb --all-namespaces -o json 2>/dev/null | jq '[.items[] | {namespace:.metadata.namespace, selector:.spec.selector.matchLabels}]' || echo '[]')
  found=$(jq -nc --argjson d "$deps" --argjson s "$sts" --argjson p "$pdbs" '
    [$d.items[] | select(.metadata.namespace | test("^kube-") | not) | select(.spec.replicas > 1) |
     {namespace:.metadata.namespace, name:.metadata.name, kind:"Deployment"} |
     select(. as $w | $p | map(select(.namespace == $w.namespace)) | length == 0)] +
    [$s.items[] | select(.metadata.namespace | test("^kube-") | not) |
     {namespace:.metadata.namespace, name:.metadata.name, kind:"StatefulSet"} |
     select(. as $w | $p | map(select(.namespace == $w.namespace)) | length == 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A6" "Use Pod Disruption Budgets" "application" "warning" "$status" \
    "$found" "$found" "Create PodDisruptionBudgets for critical workloads."
}

check_a7() {
  log "A7: Metrics Server"
  local status findings
  local ms_json node_count
  ms_json=$(kubectl get deployment metrics-server -n kube-system -o json 2>/dev/null || echo '{}')
  local avail
  avail=$(echo "$ms_json" | jq '.status.availableReplicas // 0')
  node_count=$(kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" 2>/dev/null | jq '.items | length' || echo "0")
  if [[ "$avail" -ge 1 && "$node_count" -gt 0 ]]; then
    status="PASS"
    findings='["Metrics server running with '"$avail"' replica(s); '"$node_count"' node(s) reporting metrics"]'
  else
    status="FAIL"
    findings='["Metrics server available_replicas='"$avail"', nodes_reporting='"$node_count"'"]'
  fi
  emit_result "A7" "Run Kubernetes Metrics Server" "application" "warning" "$status" \
    "$findings" '[]' "Install metrics-server via EKS managed add-on or Helm."
}

check_a8() {
  log "A8: Horizontal Pod Autoscaler"
  local deps hpas found status
  deps=$(kube_json get deployments --all-namespaces)
  hpas=$(kubectl get hpa --all-namespaces -o json 2>/dev/null | jq '[.items[] | {namespace:.metadata.namespace, target:.spec.scaleTargetRef.name}]' || echo '[]')
  found=$(jq -nc --argjson d "$deps" --argjson h "$hpas" '
    [$d.items[] | select(.metadata.namespace | test("^kube-") | not) | select(.spec.replicas > 1) |
     {namespace:.metadata.namespace, name:.metadata.name} |
     select(. as $w | $h | map(select(.namespace == $w.namespace and .target == $w.name)) | length == 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A8" "Use Horizontal Pod Autoscaler" "application" "warning" "$status" \
    "$found" "$found" "Create HPA resources for multi-replica workloads."
}

check_a9() {
  log "A9: Custom Metrics Scaling"
  local status findings detected=0
  kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" >/dev/null 2>&1 && detected=1
  kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1" >/dev/null 2>&1 && detected=1
  kubectl get deployment -n kube-system -l app=prometheus-adapter -o json 2>/dev/null | jq -e '.items | length > 0' >/dev/null 2>&1 && detected=1
  kubectl get crd scaledobjects.keda.sh >/dev/null 2>&1 && detected=1
  local custom_hpas
  custom_hpas=$(kubectl get hpa --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.metrics[]? | .type == "Pods" or .type == "Object" or .type == "External") | {namespace:.metadata.namespace, name:.metadata.name}]' || echo '[]')
  [[ $(echo "$custom_hpas" | jq 'length') -gt 0 ]] && detected=1
  if [[ $detected -eq 1 ]]; then
    status="PASS"; findings='["Custom/external metrics scaling infrastructure detected"]'
  else
    status="INFO"; findings='["No custom metrics scaling infrastructure found"]'
  fi
  emit_result "A9" "Use Custom Metrics Scaling" "application" "info" "$status" \
    "$findings" '[]' "Install Prometheus Adapter or KEDA for custom metrics scaling."
}

check_a10() {
  log "A10: Vertical Pod Autoscaler"
  local status findings detected=0
  kubectl get crd verticalpodautoscalers.autoscaling.k8s.io >/dev/null 2>&1 && detected=1
  local vpa_count
  vpa_count=$(kubectl get vpa --all-namespaces -o json 2>/dev/null | jq '.items | length' || echo "0")
  [[ "$vpa_count" -gt 0 ]] && detected=$((detected + 1))
  kubectl get deployment -n goldilocks -l app.kubernetes.io/name=goldilocks -o json 2>/dev/null | jq -e '.items | length > 0' >/dev/null 2>&1 && detected=2
  if [[ $detected -ge 2 ]]; then
    status="PASS"; findings='["VPA installed and configured ('"$vpa_count"' VPA resources)"]'
  elif [[ $detected -ge 1 ]]; then
    status="INFO"; findings='["VPA CRD found but no VPA resources configured"]'
  else
    status="INFO"; findings='["VPA not installed"]'
  fi
  emit_result "A10" "Use Vertical Pod Autoscaler" "application" "info" "$status" \
    "$findings" '[]' "Install VPA and create VerticalPodAutoscaler resources for workloads."
}

check_a11() {
  log "A11: PreStop Hooks"
  local deps sts found status
  deps=$(kube_json get deployments --all-namespaces)
  sts=$(kube_json get statefulsets --all-namespaces)
  found=$(jq -nc --argjson d "$deps" --argjson s "$sts" '
    [($d.items[], $s.items[]) | select(.metadata.namespace | test("^kube-") | not) |
     {namespace:.metadata.namespace, name:.metadata.name, containers_missing_hook:
       [.spec.template.spec.containers[] | select(.lifecycle.preStop == null) | .name]}
     | select(.containers_missing_hook | length > 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "A11" "Use PreStop Hooks" "application" "warning" "$status" \
    "$found" "$found" "Add lifecycle.preStop hooks for graceful termination."
}

check_a12() {
  log "A12: Service Mesh"
  local status findings detected=0
  kubectl get namespace istio-system >/dev/null 2>&1 && detected=1
  kubectl get crd virtualservices.networking.istio.io >/dev/null 2>&1 && detected=1
  kubectl get namespace linkerd >/dev/null 2>&1 && detected=1
  kubectl get crd serviceprofiles.linkerd.io >/dev/null 2>&1 && detected=1
  kubectl get namespace consul >/dev/null 2>&1 && detected=1
  local sidecar_count
  sidecar_count=$(kubectl get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.metadata.namespace | test("^kube-") | not) | select(.spec.containers | length > 1) | select(.spec.containers[].name | test("istio-proxy|linkerd-proxy|envoy-sidecar|consul-sidecar"))] | length' || echo "0")
  [[ "$sidecar_count" -gt 0 ]] && detected=1
  if [[ $detected -ge 1 ]]; then
    status="PASS"; findings='["Service mesh detected"]'
  else
    status="INFO"; findings='["No service mesh detected"]'
  fi
  emit_result "A12" "Use a Service Mesh" "application" "info" "$status" \
    "$findings" '[]' "Consider deploying Istio, Linkerd, or Consul for service mesh capabilities."
}

check_a13() {
  log "A13: Application Monitoring"
  local status findings detected=0
  kubectl get deployment -n monitoring -l app.kubernetes.io/name=prometheus -o json 2>/dev/null | jq -e '.items | length > 0' >/dev/null 2>&1 && detected=1
  kubectl get crd prometheuses.monitoring.coreos.com >/dev/null 2>&1 && detected=1
  kubectl get daemonset cloudwatch-agent -n amazon-cloudwatch >/dev/null 2>&1 && detected=1
  kubectl get daemonset fluent-bit -n amazon-cloudwatch >/dev/null 2>&1 && detected=1
  local third_party
  third_party=$(kubectl get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.metadata.name | test("datadog|newrelic|dynatrace"))] | length' || echo "0")
  [[ "$third_party" -gt 0 ]] && detected=1
  if [[ $detected -ge 1 ]]; then
    status="PASS"; findings='["Monitoring solution detected"]'
  else
    status="FAIL"; findings='["No monitoring solution detected"]'
  fi
  emit_result "A13" "Monitor Your Applications" "application" "warning" "$status" \
    "$findings" '[]' "Deploy Prometheus, CloudWatch Container Insights, or a third-party monitoring agent."
}

check_a14() {
  log "A14: Centralized Logging"
  local status findings detected=0
  local ds_json deploy_json
  ds_json=$(kube_json get daemonset --all-namespaces)
  deploy_json=$(kube_json get deployment --all-namespaces)
  [[ $(echo "$ds_json" | jq '[.items[] | select(.metadata.name | test("fluent-bit|fluentd|fluent"))] | length') -gt 0 ]] && detected=1
  [[ $(echo "$ds_json" | jq '[.items[] | select(.metadata.name | test("cloudwatch"))] | length') -gt 0 ]] && detected=1
  [[ $(echo "$deploy_json" | jq '[.items[] | select(.metadata.name | test("elasticsearch|opensearch|kibana|loki"))] | length') -gt 0 ]] && detected=1
  if [[ $detected -ge 1 ]]; then
    status="PASS"; findings='["Centralized logging solution detected"]'
  else
    status="FAIL"; findings='["No centralized logging solution detected"]'
  fi
  emit_result "A14" "Use Centralized Logging" "application" "warning" "$status" \
    "$findings" '[]' "Deploy Fluent Bit, CloudWatch Logs agent, or EFK/Loki stack."
}

###############################################################################
# Control Plane Checks C1–C5
###############################################################################

check_c1() {
  log "C1: Control Plane Logs"
  local status findings
  local log_types
  log_types=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
    --query 'cluster.logging.clusterLogging[?enabled==`true`].types[]' --output json 2>/dev/null || echo '[]')
  if echo "$log_types" | jq -e 'index("api")' >/dev/null 2>&1; then
    status="PASS"; findings=$(jq -nc --argjson t "$log_types" '["Enabled log types: \($t | join(", "))"]')
  else
    status="FAIL"; findings='["API server logging not enabled"]'
  fi
  emit_result "C1" "Monitor Control Plane Logs" "control_plane" "warning" "$status" \
    "$findings" '[]' "Enable at least api log type via aws eks update-cluster-config."
}

check_c2() {
  log "C2: Cluster Authentication"
  local status findings detected=0
  local access_entries
  access_entries=$(aws eks list-access-entries --cluster-name "$CLUSTER_NAME" --region "$REGION" --output json 2>/dev/null || echo '{}')
  if echo "$access_entries" | jq -e '.accessEntries | length > 0' >/dev/null 2>&1; then detected=1; fi
  local auth_cm
  auth_cm=$(kubectl get configmap aws-auth -n kube-system -o json 2>/dev/null || echo '{}')
  if echo "$auth_cm" | jq -e '.data.mapRoles != null or .data.mapUsers != null' >/dev/null 2>&1; then detected=1; fi
  if [[ $detected -ge 1 ]]; then
    status="PASS"; findings='["Cluster authentication configured"]'
  else
    status="FAIL"; findings='["No access entries or aws-auth ConfigMap found"]'
  fi
  emit_result "C2" "Cluster Authentication" "control_plane" "warning" "$status" \
    "$findings" '[]' "Configure EKS Access Entries or aws-auth ConfigMap for cluster access."
}

check_c3() {
  log "C3: Large Cluster Optimizations"
  local status findings
  local svc_count
  svc_count=$(kubectl get services --all-namespaces --no-headers 2>/dev/null | wc -l)
  if [[ "$svc_count" -lt 1000 ]]; then
    status="PASS"
    findings='["Service count '"$svc_count"' < 1000; no large-cluster optimizations needed"]'
  else
    local kp_mode warm_ip optimized=0
    kp_mode=$(kubectl get configmap kube-proxy-config -n kube-system -o json 2>/dev/null | jq -r '.data.config' 2>/dev/null | grep -oP '"mode"\s*:\s*"\K[^"]+' || echo "unknown")
    warm_ip=$(kubectl get daemonset aws-node -n kube-system -o json 2>/dev/null | jq '[.spec.template.spec.containers[0].env[] | select(.name | test("WARM_IP_TARGET|WARM_ENI_TARGET|MINIMUM_IP_TARGET"))]' || echo '[]')
    [[ "$kp_mode" == "ipvs" ]] && optimized=$((optimized + 1))
    [[ $(echo "$warm_ip" | jq 'length') -gt 0 ]] && optimized=$((optimized + 1))
    if [[ $optimized -ge 2 ]]; then
      status="PASS"; findings='["Large cluster ('"$svc_count"' services) with proper optimizations"]'
    else
      status="FAIL"; findings='["Large cluster ('"$svc_count"' services) missing optimizations: kube-proxy mode='"$kp_mode"'"]'
    fi
  fi
  emit_result "C3" "Running Large Clusters" "control_plane" "info" "$status" \
    "$findings" '[]' "For >1000 services, enable IPVS mode and configure WARM_IP_TARGET."
}

check_c4() {
  log "C4: Endpoint Access Control"
  local status findings
  local vpc_cfg
  vpc_cfg=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
    --query 'cluster.resourcesVpcConfig.{endpointPublicAccess:endpointPublicAccess,endpointPrivateAccess:endpointPrivateAccess,publicAccessCidrs:publicAccessCidrs}' \
    --output json 2>/dev/null || echo '{}')
  local pub_access cidrs
  pub_access=$(echo "$vpc_cfg" | jq -r '.endpointPublicAccess // "unknown"')
  cidrs=$(echo "$vpc_cfg" | jq -r '.publicAccessCidrs // []')
  if [[ "$pub_access" == "false" ]]; then
    status="PASS"; findings='["Fully private endpoint"]'
  elif echo "$cidrs" | jq -e 'index("0.0.0.0/0")' >/dev/null 2>&1; then
    status="FAIL"; findings='["Public endpoint open to 0.0.0.0/0"]'
  elif [[ "$pub_access" == "true" ]]; then
    status="PASS"; findings=$(jq -nc --argjson c "$cidrs" '["Public endpoint restricted to: \($c | join(", "))"]')
  else
    status="INFO"; findings='["Unable to determine endpoint access configuration"]'
  fi
  emit_result "C4" "EKS Control Plane Endpoint Access Control" "control_plane" "critical" "$status" \
    "$findings" '[]' "Restrict public endpoint access or use a fully private endpoint."
}

check_c5() {
  log "C5: Catch-All Admission Webhooks"
  local mut val found status
  mut=$(kubectl get mutatingwebhookconfigurations -o json 2>/dev/null || echo '{"items":[]}')
  val=$(kubectl get validatingwebhookconfigurations -o json 2>/dev/null || echo '{"items":[]}')
  found=$(jq -nc --argjson m "$mut" --argjson v "$val" '
    [($m.items[], $v.items[]) | {name:.metadata.name, webhooks:[.webhooks[]? |
      select((.namespaceSelector == null) and (.objectSelector == null) and
        (.rules[]? | (.apiGroups[]? == "*") or (.apiVersions[]? == "*") or (.resources[]? == "*"))) |
      {name:.name}]} | select(.webhooks | length > 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "C5" "Avoid Catch-All Admission Webhooks" "control_plane" "warning" "$status" \
    "$found" "$found" "Add namespaceSelector or objectSelector to narrow webhook scope."
}

###############################################################################
# Data Plane Checks D1–D7
###############################################################################

check_d1() {
  log "D1: Cluster Autoscaler / Karpenter"
  local status findings detected=0
  local ca_count
  ca_count=$(kubectl get deployment -n kube-system -l app=cluster-autoscaler -o json 2>/dev/null | jq '.items | length' || echo "0")
  [[ "$ca_count" -gt 0 ]] && detected=1
  kubectl get namespace karpenter >/dev/null 2>&1 && detected=1
  kubectl get crd nodepools.karpenter.sh >/dev/null 2>&1 && detected=1
  kubectl get crd ec2nodeclasses.karpenter.k8s.aws >/dev/null 2>&1 && detected=1
  if [[ $detected -ge 1 ]]; then
    status="PASS"; findings='["Node autoscaling solution detected"]'
  else
    status="FAIL"; findings='["No Cluster Autoscaler or Karpenter found"]'
  fi
  emit_result "D1" "Use Cluster Autoscaler or Karpenter" "data_plane" "critical" "$status" \
    "$findings" '[]' "Install Karpenter or Cluster Autoscaler for automatic node scaling."
}

check_d2() {
  log "D2: Multi-AZ Node Spread"
  local status findings
  local nodes_json az_info
  nodes_json=$(kube_json get nodes)
  az_info=$(echo "$nodes_json" | jq '[.items[] | {name:.metadata.name, az:.metadata.labels["topology.kubernetes.io/zone"]}] | group_by(.az) | map({az:.[0].az, count:length})')
  local az_count
  az_count=$(echo "$az_info" | jq 'length')
  if [[ "$az_count" -lt 2 ]]; then
    status="FAIL"
    findings=$(jq -nc --argjson a "$az_info" '["Nodes in only \($a | length) AZ(s): \($a | map(.az) | join(", "))"]')
  else
    local variance
    variance=$(echo "$az_info" | jq '(map(.count) | (max - min) / max * 100) | floor')
    if [[ "$variance" -le 20 ]]; then
      status="PASS"
    else
      status="FAIL"
    fi
    findings=$(jq -nc --argjson a "$az_info" --arg v "$variance" '["AZ distribution: \($a | map("\(.az)=\(.count)") | join(", ")); variance=\($v)%"]')
  fi
  emit_result "D2" "Worker Nodes Spread Across Multiple AZs" "data_plane" "critical" "$status" \
    "$findings" '[]' "Use multiple AZs with balanced node groups for high availability."
}

check_d3() {
  log "D3: Resource Requests/Limits"
  local deps found status
  deps=$(kube_json get deployments --all-namespaces)
  found=$(echo "$deps" | jq '[.items[] | select(.metadata.namespace | test("^kube-") | not) |
    {namespace:.metadata.namespace, name:.metadata.name, containers_missing_resources:
      [.spec.template.spec.containers[] | {name:.name,
        has_cpu_request:(.resources.requests.cpu != null), has_cpu_limit:(.resources.limits.cpu != null),
        has_mem_request:(.resources.requests.memory != null), has_mem_limit:(.resources.limits.memory != null)}
       | select(.has_cpu_request == false or .has_cpu_limit == false or .has_mem_request == false or .has_mem_limit == false)]}
    | select(.containers_missing_resources | length > 0)]')
  if [[ $(echo "$found" | jq 'length') -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "D3" "Configure Resource Requests/Limits" "data_plane" "critical" "$status" \
    "$found" "$found" "Set CPU/memory requests and limits for all containers."
}

check_d4() {
  log "D4: Namespace ResourceQuotas"
  local missing=()
  for ns in "${FILTERED_NS[@]}"; do
    local count
    count=$(kubectl get resourcequota -n "$ns" --no-headers 2>/dev/null | wc -l)
    if [[ "$count" -eq 0 ]]; then missing+=("$ns"); fi
  done
  local found status
  found=$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc '.')
  if [[ ${#missing[@]} -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "D4" "Namespace ResourceQuotas" "data_plane" "warning" "$status" \
    "$found" "$found" "Create ResourceQuota in each namespace to enforce resource limits."
}

check_d5() {
  log "D5: Namespace LimitRanges"
  local missing=()
  for ns in "${FILTERED_NS[@]}"; do
    local count
    count=$(kubectl get limitrange -n "$ns" --no-headers 2>/dev/null | wc -l)
    if [[ "$count" -eq 0 ]]; then missing+=("$ns"); fi
  done
  local found status
  found=$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc '.')
  if [[ ${#missing[@]} -eq 0 ]]; then status="PASS"; else status="FAIL"; fi
  emit_result "D5" "Namespace LimitRanges" "data_plane" "warning" "$status" \
    "$found" "$found" "Create LimitRange in each namespace to set default resource constraints."
}

check_d6() {
  log "D6: CoreDNS Metrics Monitoring"
  local status findings detected=0
  local metrics_port
  metrics_port=$(kubectl get deployment coredns -n kube-system -o json 2>/dev/null | jq '[.spec.template.spec.containers[0].ports[] | select(.containerPort == 9153)] | length' || echo "0")
  local svcmon
  svcmon=$(kubectl get servicemonitor -n kube-system -o json 2>/dev/null | jq '[.items[] | select(.spec.selector.matchLabels["k8s-app"] == "kube-dns" or (.metadata.name | test("coredns|dns")))] | length' || echo "0")
  local prom_ann
  prom_ann=$(kubectl get service kube-dns -n kube-system -o json 2>/dev/null | jq '.metadata.annotations | with_entries(select(.key | test("prometheus"))) | length' || echo "0")
  [[ "$metrics_port" -gt 0 ]] && detected=$((detected + 1))
  [[ "$svcmon" -gt 0 || "$prom_ann" -gt 0 ]] && detected=$((detected + 1))
  if [[ $detected -ge 2 ]]; then
    status="PASS"; findings='["CoreDNS metrics port exposed and monitoring configured"]'
  elif [[ "$metrics_port" -gt 0 ]]; then
    status="FAIL"; findings='["CoreDNS metrics port exists but no ServiceMonitor or scrape annotations found"]'
  else
    status="FAIL"; findings='["CoreDNS metrics not properly configured"]'
  fi
  emit_result "D6" "Monitor CoreDNS Metrics" "data_plane" "warning" "$status" \
    "$findings" '[]' "Ensure CoreDNS metrics port 9153 is exposed and monitored by Prometheus."
}

check_d7() {
  log "D7: CoreDNS Configuration"
  local status findings
  local auto_mode
  auto_mode=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
    --query 'cluster.computeConfig.enabled' --output text 2>/dev/null || echo "false")
  if [[ "$auto_mode" == "true" || "$auto_mode" == "True" ]]; then
    status="PASS"; findings='["EKS Auto Mode enabled — CoreDNS managed automatically"]'
  else
    local addon_status
    addon_status=$(aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name coredns --region "$REGION" \
      --query 'addon.status' --output text 2>/dev/null || echo "")
    if [[ -n "$addon_status" ]]; then
      status="PASS"; findings='["CoreDNS is an EKS managed add-on (status: '"$addon_status"')"]'
    else
      status="FAIL"; findings='["CoreDNS is self-managed — consider using EKS managed add-on"]'
    fi
  fi
  emit_result "D7" "CoreDNS Configuration" "data_plane" "info" "$status" \
    "$findings" '[]' "Use EKS managed add-on for CoreDNS to get automatic updates."
}

###############################################################################
# Output
###############################################################################

write_json() {
  local out="$OUTPUT_DIR/assessment.json"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  {
    echo "{"
    echo "  \"cluster\": \"$CLUSTER_NAME\","
    echo "  \"region\": \"$REGION\","
    echo "  \"timestamp\": \"$ts\","
    echo "  \"summary\": {\"total\": $TOTAL, \"pass\": $PASS, \"fail\": $FAIL, \"info\": $INFO},"
    echo "  \"checks\": ["
    local first=1
    for r in "${RESULTS[@]}"; do
      [[ $first -eq 0 ]] && echo ","
      echo "    $r"
      first=0
    done
    echo ""
    echo "  ]"
    echo "}"
  } | jq '.' > "$out"
  log "Wrote $out"
}

write_report() {
  local out="$OUTPUT_DIR/assessment-report.md"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  {
    echo "# EKS Resilience Assessment Report"
    echo ""
    echo "- **Cluster:** $CLUSTER_NAME"
    echo "- **Region:** $REGION"
    echo "- **Date:** $ts"
    echo ""
    echo "## Summary"
    echo ""
    echo "| Total | PASS | FAIL | INFO |"
    echo "|-------|------|------|------|"
    echo "| $TOTAL | $PASS | $FAIL | $INFO |"
    echo ""

    for category in application control_plane data_plane; do
      local title
      case $category in
        application)    title="Application Checks" ;;
        control_plane)  title="Control Plane Checks" ;;
        data_plane)     title="Data Plane Checks" ;;
      esac
      echo "## $title"
      echo ""
      echo "| ID | Check | Severity | Status |"
      echo "|----|-------|----------|--------|"
      for r in "${RESULTS[@]}"; do
        local cat
        cat=$(echo "$r" | jq -r '.category')
        [[ "$cat" != "$category" ]] && continue
        local id name sev st
        id=$(echo "$r" | jq -r '.id')
        name=$(echo "$r" | jq -r '.name')
        sev=$(echo "$r" | jq -r '.severity')
        st=$(echo "$r" | jq -r '.status')
        local icon
        case $st in PASS) icon="✅";; FAIL) icon="❌";; *) icon="ℹ️";; esac
        echo "| $id | $name | $sev | $icon $st |"
      done
      echo ""
    done

    # Details for FAILed checks
    local has_fail=0
    for r in "${RESULTS[@]}"; do
      [[ $(echo "$r" | jq -r '.status') == "FAIL" ]] && has_fail=1 && break
    done
    if [[ $has_fail -eq 1 ]]; then
      echo "## Failed Check Details"
      echo ""
      for r in "${RESULTS[@]}"; do
        [[ $(echo "$r" | jq -r '.status') != "FAIL" ]] && continue
        local id name rem findings
        id=$(echo "$r" | jq -r '.id')
        name=$(echo "$r" | jq -r '.name')
        rem=$(echo "$r" | jq -r '.remediation')
        findings=$(echo "$r" | jq -r '.findings | if type == "array" then map(if type == "string" then . else (. | tostring) end) | join("; ") else tostring end')
        echo "### $id: $name"
        echo ""
        echo "**Findings:** $findings"
        echo ""
        echo "**Remediation:** $rem"
        echo ""
      done
    fi
  } > "$out"
  log "Wrote $out"
}

print_summary() {
  echo ""
  echo "=========================================="
  echo " EKS Resilience Assessment — $CLUSTER_NAME"
  echo "=========================================="
  echo " PASS: $PASS / $TOTAL"
  echo " FAIL: $FAIL / $TOTAL"
  echo " INFO: $INFO / $TOTAL"
  echo "=========================================="
  echo " Output: $OUTPUT_DIR/assessment.json"
  echo "         $OUTPUT_DIR/assessment-report.md"
  echo "=========================================="
}

###############################################################################
# Main
###############################################################################

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cluster)    CLUSTER_NAME="$2"; shift 2 ;;
      --region)     REGION="$2"; shift 2 ;;
      --namespaces) NAMESPACES="$2"; shift 2 ;;
      --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
      -h|--help)    usage ;;
      *)            die "Unknown option: $1" ;;
    esac
  done

  check_deps
  discover_cluster
  get_namespaces
  mkdir -p "$OUTPUT_DIR"

  # Application checks
  check_a1; check_a2; check_a3; check_a4; check_a5
  check_a6; check_a7; check_a8; check_a9; check_a10
  check_a11; check_a12; check_a13; check_a14

  # Control plane checks
  check_c1; check_c2; check_c3; check_c4; check_c5

  # Data plane checks
  check_d1; check_d2; check_d3; check_d4; check_d5
  check_d6; check_d7

  write_json
  write_report
  print_summary
}

main "$@"
