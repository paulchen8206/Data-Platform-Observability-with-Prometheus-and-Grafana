# Local Production-Like Kubernetes (kind + Helm + Argo CD)

This guide deploys the full stack from this repository to Kubernetes in Docker (kind), managed by Argo CD and Helm.

## What gets deployed

- Data platform core via local Helm chart:
  - Zookeeper, Kafka, Kafka init job
  - Schema Registry
  - MinIO + init job
  - Spark master/worker, producer, spark-job
  - Kafka UI, Kafka exporter
- Monitoring via Helm charts:
  - kube-prometheus-stack (Prometheus, Alertmanager, Grafana)
  - Loki
  - Alloy

## Prerequisites

- `kind`, `kubectl`, `helm`, `docker`
- Kubernetes context points to your kind cluster
- Argo CD CLI optional (not required for bootstrap)

## 1. Build local images and load into kind

```bash
# Producer image
cd producer-app && docker build -t data-platform-grafana-prometheus-producer:latest . && cd ..

# Spark runtime image (for spark-master/spark-worker)
cd spark-job && docker build --target spark-runtime -t data-platform-grafana-prometheus-spark-runtime:latest . && cd ..

# Spark job image
cd spark-job && docker build -t data-platform-grafana-prometheus-spark-job:latest . && cd ..

# Load into kind cluster (replace cluster name if needed)
kind load docker-image data-platform-grafana-prometheus-producer:latest
kind load docker-image data-platform-grafana-prometheus-spark-runtime:latest
kind load docker-image data-platform-grafana-prometheus-spark-job:latest
```

## 2. Create required secrets

```bash
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=change-me \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 3. Install Argo CD

```bash
make k8s-argocd-install
```

Get initial admin password:

```bash
make k8s-argocd-password
```

## 4. Bootstrap Argo CD app-of-apps

Set your repository URL explicitly if needed:

```bash
make k8s-argocd-bootstrap ARGOCD_REPO_URL=https://github.com/<org>/<repo>.git
```

If `origin` is set correctly, this also works:

```bash
make k8s-argocd-bootstrap
```

## 5. Verify applications

```bash
kubectl -n argocd get applications
kubectl -n data-platform get pods
kubectl -n monitoring get pods
```

## Optional direct Helm installs (without Argo CD)

```bash
make k8s-preflight
make k8s-core-install
make k8s-stack-install
```

## Notes

- This flow is production-like for local development, not production-hardened by default.
- For real production, keep secrets externalized, enforce TLS/Ingress policies, and use managed storage classes.
