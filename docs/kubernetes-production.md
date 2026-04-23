# Kubernetes Production Option

This repository includes a production-like Kubernetes deployment path for local testing.

## Why this approach

Deploying Grafana with the official Helm chart (`grafana/grafana`) is an industry-standard choice for production because it supports:

- Managed upgrades through Helm.
- Easy GitOps integration through versioned values files.
- Horizontal scaling with multiple replicas.
- Strong integration with Prometheus-based monitoring stacks.

For full monitoring in Kubernetes, `kube-prometheus-stack` is recommended because it bundles Prometheus, Alertmanager, and Grafana with Kubernetes-focused defaults and dashboards.

## Deployment options

### Option A: Grafana only (official chart)

Use this when you already have Prometheus/Alertmanager managed separately.

```bash
make k8s-grafana-install
```

Upgrade:

```bash
make k8s-grafana-upgrade
```

Uninstall:

```bash
make k8s-grafana-uninstall
```

Values file:

- `k8s/values-grafana-prod.yaml`

### Option B: Full stack (`kube-prometheus-stack`)

Use this for a complete production-like monitoring baseline.

```bash
make k8s-stack-install
```

Upgrade:

```bash
make k8s-stack-upgrade
```

Uninstall:

```bash
make k8s-stack-uninstall
```

Values file:

- `k8s/values-kube-prometheus-stack-prod.yaml`

## Key production considerations

### 1. Helm-based lifecycle

Use the chart release lifecycle (`install`, `upgrade`, `rollback`) to keep updates repeatable and auditable.

### 2. Persistence (PVC)

Enable persistence for Grafana so dashboards, alert rules, and runtime state survive pod restarts.

- `persistence.enabled: true`
- Persistent Volume Claims are defined in the provided values files.

### 3. High availability (HA)

Use multiple replicas:

- Grafana replicas set to `2`
- Prometheus and Alertmanager replicas set to `2` in stack mode

### 4. Resource limits and requests

Set explicit CPU/memory requests and limits to avoid noisy-neighbor impact and scheduling instability.

### 5. Security

- Do not use default admin credentials.
- Store secrets in Kubernetes Secrets.
- Provided values expect an existing secret named `grafana-admin`.

Create it (example):

```bash
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=<user> \
  --from-literal=admin-password=<strong-password>
```

### 6. GitOps compatibility

Treat Helm values and dashboard definitions as code in Git.

- Keep values files under version control.
- Manage dashboard provisioning through ConfigMaps or synced files.

### 7. Ingress and external access

Ingress is enabled in values files for secure external access.

- Update hostnames, ingress class, and TLS settings for your environment.

### 8. External database for Grafana (recommended at scale)

For high-volume production, use PostgreSQL (or equivalent) instead of sqlite for better concurrency and reliability.

A template is included in `k8s/values-grafana-prod.yaml` as commented environment variables.

## Namespace and tools

Defaults in Makefile:

- Namespace: `monitoring`
- Helm command: `helm`
- Kubectl command: `kubectl`

Override example:

```bash
make k8s-stack-install K8S_NAMESPACE=observability
```
