# Data Platform Observability with Prometheus and Grafana

A reference project for operating a small event-driven data platform together with a complete observability stack.

## What this repository contains

- Data pipeline: `source-ingestion` -> Kafka -> `spark-extraction` -> Iceberg on MinIO.
- Metrics and alerting: Prometheus, Alertmanager, exporters.
- Logs and alerting: Alloy -> Loki (+ Loki rules).
- Visualization: Grafana dashboards and Explore.
- Deployment modes: Docker routine, Kubernetes Helm routine, Kubernetes Argo CD routine.

## Quick start by routine

### Docker routine

```bash
make routine-up-docker
make routine-status-docker
```

Stop:

```bash
make routine-down-docker
```

### Kubernetes routine (Helm)

```bash
make routine-up-helm
make routine-status-helm
```

Stop:

```bash
make routine-down-helm
```

### Kubernetes routine (Argo CD)

```bash
make routine-up-argocd
make routine-status-argocd
```

Stop:

```bash
make routine-down-argocd
```

### Compatibility wrappers

If you prefer the old interface:

```bash
make routine-up ROUTINE=docker
make routine-status ROUTINE=helm
make routine-down ROUTINE=argocd
```

## Primary local endpoints

### Docker routine endpoints

- Grafana: <http://localhost:3000>
- Prometheus: <http://localhost:9090>
- Alertmanager: <http://localhost:9093>
- Loki: <http://localhost:3100>
- Kafka UI: <http://localhost:8085>
- Spark Master UI: <http://localhost:8080>
- MinIO Console: <http://localhost:9001>

### Kubernetes routine endpoints

Use `kubectl port-forward` from the appropriate namespace. Operational examples are in docs.

## Documentation map

- Architecture and design model: [docs/architecture.md](docs/architecture.md)
- Local Kubernetes + Helm/Argo CD operations: [docs/local-kubernetes-argocd.md](docs/local-kubernetes-argocd.md)
- Production Kubernetes blueprint: [docs/production-kubernetes.md](docs/production-kubernetes.md)
- Day-2 runbook and incident playbooks: [docs/operations-runbook.md](docs/operations-runbook.md)

## Repository layout

- `docker-compose.yml`: local service topology.
- `Makefile`: routines and lifecycle commands.
- `k8s/`: Helm values and local deployment assets.
- `argocd/`: Argo CD app definitions.
- `observability/`: ServiceMonitors, rules, dashboard manifests.
- `prometheus/`, `loki/`, `grafana/`, `alloy/`: observability configs.

## Notes

- For local reproducibility, Grafana provisioning and SQLite repair logic are codified in `k8s/values-kube-prometheus-stack-prod.yaml`.
- Avoid mixed ownership of the same Kubernetes resources between Helm and Argo CD.
