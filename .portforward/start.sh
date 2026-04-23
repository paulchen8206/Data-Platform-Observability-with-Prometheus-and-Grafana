#!/usr/bin/env bash
set -euo pipefail

MAP_FILE=".portforward/map.txt"
PID_FILE=".portforward/pids.txt"
LOG_DIR=".portforward/logs"
mkdir -p "$LOG_DIR"
: > "$MAP_FILE"
: > "$PID_FILE"

if [[ -f .portforward/pids.txt ]]; then
  while read -r pid; do
    [[ -n "$pid" ]] && kill "$pid" >/dev/null 2>&1 || true
  done < .portforward/pids.txt
fi

entries=(
  "monitoring svc/kube-prometheus-stack-grafana 3000 80"
  "monitoring svc/kube-prometheus-stack-prometheus 9090 9090"
  "monitoring svc/kube-prometheus-stack-alertmanager 9093 9093"
  "monitoring svc/loki 3100 3100"
  "monitoring svc/alloy 12345 12345"
  "monitoring svc/kube-prometheus-stack-kube-state-metrics 8082 8080"
  "monitoring svc/kube-prometheus-stack-prometheus-node-exporter 9100 9100"
  "monitoring svc/kube-prometheus-stack-operator 9443 443"
  "data-platform svc/kafka-ui 8080 8080"
  "data-platform svc/schema-registry 8081 8081"
  "data-platform svc/spark-master 8088 8080"
  "data-platform svc/spark-master 7077 7077"
  "data-platform svc/minio 9000 9000"
  "data-platform svc/minio 9001 9001"
  "data-platform svc/kafka-exporter 9308 9308"
  "data-platform svc/zookeeper 2181 2181"
  "data-platform svc/kafka 9092 9092"
)

for entry in "${entries[@]}"; do
  ns=$(awk '{print $1}' <<<"$entry")
  target=$(awk '{print $2}' <<<"$entry")
  lport=$(awk '{print $3}' <<<"$entry")
  rport=$(awk '{print $4}' <<<"$entry")

  if lsof -iTCP:"$lport" -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    echo "SKIP $ns $target localhost:$lport (already in use)" >> "$MAP_FILE"
    continue
  fi

  nohup kubectl -n "$ns" port-forward "$target" "$lport":"$rport" > "$LOG_DIR/${ns}_$(basename "$target")_${lport}.log" 2>&1 &
  pid=$!
  echo "$pid" >> "$PID_FILE"
  echo "$ns $target http://localhost:$lport (remote:$rport pid:$pid)" >> "$MAP_FILE"
  sleep 0.2
done

echo "Port-forward map: $MAP_FILE"
cat "$MAP_FILE"
