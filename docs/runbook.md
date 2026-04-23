# Runbook

## Prerequisites

- Docker Desktop is running.
- Ports used by the stack are available (`3000`, `3100`, `8080`, `8081`, `8085`, `8086`, `8088`, `9000`, `9001`, `9090`, `9093`, `12345`).

## Start

Start everything:

```bash
make up
```

Or split startup:

```bash
make up-core
make up-monitoring
```

Check status:

```bash
make ps
```

## Stop

```bash
make down
```

Remove volumes and orphans:

```bash
make down-v
```

## Daily Checks

Quick health sweep:

```bash
make health
```

Key logs:

```bash
make logs-spark
make logs-producer
make logs-alloy
```

## Data Validation

Run Iceberg verification query:

```bash
make verify-iceberg
```

## Monitoring Validation

Inspect configured rules:

```bash
make rules-prometheus
make rules-loki
```

Check Loki labels and sample docker stream:

```bash
make check-loki
```

Check Kafka lag series for topic:

```bash
make check-kafka-alert-series
```

Override topic:

```bash
make check-kafka-alert-series TOPIC=platform-events
```

## Common Recovery Steps

### Rebuild Spark job after code changes

```bash
make spark-rebuild
```

### Reset Spark checkpoints

```bash
make reset-checkpoints
```

### Restart monitoring components

```bash
make monitoring-recreate
```

## Kubernetes Production-Like Option

If you want to validate a production-oriented Kubernetes deployment locally:

```bash
make k8s-repo-setup
make k8s-grafana-install
```

Or deploy the full monitoring stack:

```bash
make k8s-repo-setup
make k8s-stack-install
```

For full setup and production considerations, see [kubernetes-production.md](kubernetes-production.md).

For a full local kind + Argo CD + Helm flow, see [k8s-argocd-local.md](k8s-argocd-local.md).

## Useful Endpoints

- Grafana: `http://localhost:3000` (`admin` / `admin`)
- Prometheus: `http://localhost:9090`
- Alertmanager: `http://localhost:9093`
- Loki: `http://localhost:3100`
- Alloy: `http://localhost:12345`
- Kafka UI: `http://localhost:8085`
- Spark Master UI: `http://localhost:8080`

## Known Local Caveat

On some Docker Desktop hosts, cAdvisor may expose stable per-container metrics but not Compose service labels. If Spark service-name panels are empty, validate with container `id` based queries first.
