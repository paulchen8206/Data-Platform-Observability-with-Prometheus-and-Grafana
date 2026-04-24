# Production Kubernetes Blueprint

## Scope

This document defines production-oriented deployment guidelines derived from the architecture model.

## Ownership model

Use one control plane per resource set:

- Option A: Helm-owned monitoring and core services.
- Option B: Argo CD-owned apps that render Helm/manifests.

Do not mix ownership for the same deployment/statefulset/service.

## Deployment baseline

1. Separate namespaces for data platform, monitoring, and GitOps control plane.
2. Persistent volumes for Kafka, Grafana, Prometheus, Loki, MinIO.
3. Explicit CPU/memory requests and limits for all workloads.
4. Declarative dashboards/datasources/alerts in Git.

## Security baseline

1. Replace default credentials and rotate secrets.
2. Use external secret manager integration where possible.
3. Enable ingress TLS and restrict admin UIs.
4. Enforce RBAC least privilege per namespace and service account.

## Reliability baseline

1. Multi-replica control-plane services where supported.
2. PodDisruptionBudgets for critical workloads.
3. Backups for stateful data and Grafana metadata.
4. Controlled upgrade strategy and rollback plan per release.

## Observability baseline

1. Prometheus retention and storage sizing are explicit.
2. Loki storage backend and retention are explicit.
3. Alert routing policy is versioned.
4. SLO dashboards and runbook links are attached to alerts.

## Release workflow

1. Validate changes in local Kubernetes routine.
2. Promote via branch/PR with config diff review.
3. Apply/sync through the selected owner (Helm or Argo CD).
4. Run post-deploy verification checks and dashboards.

## Suggested production checklist

- [ ] Ownership model selected and documented.
- [ ] Secrets externalized.
- [ ] Ingress/TLS configured.
- [ ] Storage classes and backup policies validated.
- [ ] Alert routes tested.
- [ ] Runbook updated with environment-specific commands.

## Related docs

- Architecture: [docs/architecture.md](docs/architecture.md)
- Local operational routines: [docs/local-kubernetes-argocd.md](docs/local-kubernetes-argocd.md)
- Incident operations: [docs/operations-runbook.md](docs/operations-runbook.md)
