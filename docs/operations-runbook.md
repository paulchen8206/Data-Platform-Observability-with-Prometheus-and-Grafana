# Operations Runbook

## Scope

Day-2 operations, verification, and incident playbooks for all three routines.

## Routine operations

### Docker routine

Start and verify:

```bash
make routine-up-docker
make routine-status-docker
```

Stop:

```bash
make routine-down-docker
```

### Kubernetes Helm routine

Start and verify:

```bash
make routine-up-helm
make routine-status-helm
```

Stop:

```bash
make routine-down-helm
```

### Kubernetes Argo CD routine

Start and verify:

```bash
make routine-up-argocd
make routine-status-argocd
```

Stop:

```bash
make routine-down-argocd
```

## Daily health checks

```bash
make health
make rules-prometheus
make rules-loki
make check-loki
make check-kafka-alert-series
```

For Kubernetes:

```bash
kubectl get pods -n data-platform
kubectl get pods -n monitoring
kubectl get pods -n argocd
```

## Data validation checks

```bash
make verify-iceberg
make verify-warehouse-k8s
```

## Incident playbooks

### 1) Grafana login fails

1. Confirm Grafana pod is running:

```bash
kubectl -n monitoring get pods -l app.kubernetes.io/name=grafana
```

2. Verify admin secret values:

```bash
kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

3. Recreate local access tunnel:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 33000:80
```

4. Retry in a private browser window to avoid stale cookie/session issues.

### 2) Kafka UI shows no topic/schema

1. Verify topic exists:

```bash
kubectl -n data-platform exec deploy/kafka -- \
  kafka-topics --bootstrap-server kafka:9092 --list
```

2. Create missing topic if needed:

```bash
kubectl -n data-platform exec deploy/kafka -- \
  kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic platform-events --partitions 3 --replication-factor 1
```

3. Verify schema subject:

```bash
kubectl -n data-platform exec deploy/schema-registry -- \
  curl -s http://localhost:8081/subjects
```

4. Reconnect Kafka UI tunnel:

```bash
kubectl -n data-platform port-forward svc/kafka-ui 18080:8080
```

### 3) Argo CD UI not reachable

1. Confirm pods:

```bash
kubectl -n argocd get pods
```

2. Start tunnel:

```bash
kubectl -n argocd port-forward svc/argocd-server 18081:443
```

3. Get initial password:

```bash
make k8s-argocd-password
```

## Recovery utilities

```bash
make spark-rebuild
make reset-checkpoints
make monitoring-recreate
```

## Compatibility commands (legacy)

```bash
make routine-up ROUTINE=docker
make routine-status ROUTINE=helm
make routine-down ROUTINE=argocd
```
