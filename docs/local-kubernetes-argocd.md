# Local Kubernetes Operations (Helm and Argo CD)

## Scope

This document is only for local Kubernetes operations on minikube.

## Prerequisites

- `minikube`, `kubectl`, `helm`, `docker`
- Docker Desktop running
- Git remote configured for Argo CD bootstrap (`ARGOCD_REPO_URL`)

## Routine quickstarts

### Helm routine

```bash
make routine-up-helm
make routine-status-helm
```

### Argo CD routine

```bash
make routine-up-argocd
make routine-status-argocd
```

### Stop either Kubernetes routine

```bash
make routine-down-helm
# or
make routine-down-argocd
```

## What each routine does

### `routine-up-helm`

1. Starts minikube and sets context.
2. Builds local images in minikube Docker.
3. Ensures namespaces and `grafana-admin` secret.
4. Installs Helm releases for core, monitoring, Loki, and Alloy.
5. Applies observability manifests under `k8s/observability`.

### `routine-up-argocd`

1. Runs the same minikube/bootstrap preparation.
2. Installs Argo CD in `argocd` namespace.
3. Bootstraps app-of-apps and child apps from `argocd/`.

## Verification commands

```bash
kubectl get pods -n data-platform
kubectl get pods -n monitoring
kubectl get pods -n argocd
helm list -A
kubectl get applications.argoproj.io -n argocd
```

## Common local UI access

### Argo CD UI

```bash
kubectl -n argocd port-forward svc/argocd-server 18081:443
```

Open <https://localhost:18081>.

Get initial password:

```bash
make k8s-argocd-password
```

### Grafana UI

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 33000:80
```

Open <http://localhost:33000>.

### Kafka UI

```bash
kubectl -n data-platform port-forward svc/kafka-ui 18080:8080
```

Open <http://localhost:18080>.

## Troubleshooting

### Argo CD CRD annotation size error

If install fails with CRD annotation length issues:

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side=true --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
make k8s-argocd-bootstrap
```

### Helm and Argo CD ownership conflict

Do not have Helm and Argo CD manage the same resources simultaneously. Pick one owner per component set.

### Grafana login/availability issues

Use runbook playbook: [docs/operations-runbook.md](docs/operations-runbook.md).
