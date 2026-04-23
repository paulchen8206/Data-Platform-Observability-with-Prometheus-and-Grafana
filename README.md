# Data Platform (Local Docker Compose)

Local end-to-end data platform for development and observability.

- Producer writes Avro events to Kafka.
- Spark Structured Streaming reads from Kafka and writes to Iceberg on MinIO.
- Prometheus and Grafana provide metrics dashboards and alerting.
- Alloy ships Docker logs to Loki.

## Table Of Contents

- [Quick Start](#quick-start)
- [Developer Commands](#developer-commands)
- [Documentation](#documentation)
- [Kubernetes Production Option](#kubernetes-production-option)
- [Kubernetes In Docker With Argo CD](#kubernetes-in-docker-with-argo-cd)
- [Notes](#notes)

## Quick Start

```bash
make up
make ps
```

Open:

- Grafana: <http://localhost:3000>
- Prometheus: <http://localhost:9090>
- Loki: <http://localhost:3100>
- Alloy UI/metrics: <http://localhost:12345>
- Kafka UI: <http://localhost:8085>
- Spark Master UI: <http://localhost:8080>

Stop:

```bash
make down
```

## Developer Commands

```bash
make help
```

Most used:

- `make up-core`
- `make up-monitoring`
- `make logs-spark`
- `make logs-producer`
- `make logs-alloy`
- `make health`
- `make verify-iceberg`

## Documentation

- Architecture: [docs/architecture.md](docs/architecture.md)
- Runbook: [docs/runbook.md](docs/runbook.md)
- Kubernetes production option: [docs/kubernetes-production.md](docs/kubernetes-production.md)
- kind + Argo CD deployment: [docs/k8s-argocd-local.md](docs/k8s-argocd-local.md)

## Kubernetes Production Option

Production-like local Kubernetes deployment is available via Helm:

- Option A: official Grafana chart (`grafana/grafana`)
- Option B: full monitoring stack (`prometheus-community/kube-prometheus-stack`)

See [docs/kubernetes-production.md](docs/kubernetes-production.md) for production guidance on PVCs, HA replicas, resource limits, GitOps, security, ingress, and external database recommendations.

## Kubernetes In Docker With Argo CD

Use Helm + Argo CD to deploy the local stack into kind with GitOps sync.

Entry points:

- `make k8s-preflight`
- `make k8s-argocd-install`
- `make k8s-argocd-bootstrap`

Full steps are in [docs/k8s-argocd-local.md](docs/k8s-argocd-local.md).

## Notes

- This project uses Alloy (not Promtail) for local log collection.
- Default local credentials are kept in compose and provisioning files for development convenience only.
