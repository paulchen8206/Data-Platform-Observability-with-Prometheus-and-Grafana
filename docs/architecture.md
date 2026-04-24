# Architecture

## 1. Design idea

This project is built around one operational idea:

- Run a realistic data pipeline and observability stack using repeatable routines.
- Keep deployment ownership explicit so routine execution is deterministic.
- Keep observability declarative so dashboards/datasources/alerts survive restarts and resets.

### Design principles

1. Telemetry-first operations: metrics, logs, and alerts are first-class deliverables.
2. Deterministic routines: Docker, Helm, and Argo CD routines are explicit and testable.
3. Clear ownership boundaries: each deployment path has a clearly defined owner.
4. Docs-as-operations: architecture, routines, and runbook stay synchronized.

## 2. System context

```mermaid
flowchart LR
  subgraph DataPlane[Data Platform]
    P[source-ingestion]
    K[Kafka]
    S[spark-extraction]
    M[MinIO Iceberg warehouse]
  end

  subgraph ObsPlane[Observability Platform]
    E[Exporters + Alloy]
    PR[Prometheus]
    L[Loki]
    G[Grafana]
    A[Alertmanager]
  end

  P --> K --> S --> M
  K --> E
  S --> E
  E --> PR
  E --> L
  PR --> G
  L --> G
  PR --> A
  L --> A
```

## 3. Runtime data and telemetry flow

```mermaid
sequenceDiagram
  participant Producer as source-ingestion
  participant Kafka as Kafka
  participant Spark as spark-extraction
  participant MinIO as MinIO/Iceberg
  participant Exporters as Exporters+Alloy
  participant Prom as Prometheus
  participant Loki as Loki
  participant Grafana as Grafana
  participant AM as Alertmanager

  Producer->>Kafka: publish platform-events
  Spark->>Kafka: consume platform-events
  Spark->>MinIO: write Iceberg data files/metadata

  Kafka->>Exporters: expose metrics/logs
  Spark->>Exporters: expose metrics/logs
  Exporters->>Prom: scrape targets
  Exporters->>Loki: push logs

  Prom->>Grafana: query metrics
  Loki->>Grafana: query logs
  Prom->>AM: fire metric alerts
  Loki->>AM: fire log alerts
```

## 4. Deployment ownership model

```mermaid
flowchart TB
  subgraph DockerRoutine[Docker routine owner: docker compose]
    DC[docker-compose services]
  end

  subgraph HelmRoutine[Kubernetes Helm routine owner: Helm]
    HCore[data-platform-core release]
    HMon[kube-prometheus-stack release]
    HLoki[loki release]
    HAlloy[alloy release]
  end

  subgraph ArgoRoutine[Kubernetes Argo CD routine owner: Argo CD]
    AApp[app-of-apps]
    ACore[core app]
    AMon[monitoring app]
    ALoki[loki app]
    AAlloy[alloy app]
  end

  note1[Rule: avoid dual ownership for same resources]

  DockerRoutine --- note1
  HelmRoutine --- note1
  ArgoRoutine --- note1
```

## 5. Routine-to-deployment mapping

| Routine target | Control plane | Expected deployment behavior |
| --- | --- | --- |
| `routine-up-docker` | Docker Compose | Starts local containers from `docker-compose.yml` |
| `routine-up-helm` | Minikube + Helm | Builds local images and installs Helm releases |
| `routine-up-argocd` | Minikube + Argo CD | Installs Argo CD and syncs app-of-apps |
| `routine-status-*` | Routine-specific | Reports health for the active routine |
| `routine-down-*` | Routine-specific | Stops local stack or minikube profile |

## 6. Relevant Kubernetes deployments by namespace

```mermaid
flowchart LR
  subgraph DP[data-platform namespace]
    zk[zookeeper]
    kafka[kafka]
    sr[schema-registry]
    producer[source-ingestion]
    spark[spark-extraction + spark master/worker]
    minio[minio]
    kui[kafka-ui]
  end

  subgraph MON[monitoring namespace]
    prom[prometheus]
    graf[grafana]
    am[alertmanager]
    loki[loki]
    alloy[alloy]
    exp[kafka-exporter/node-exporter/cadvisor]
  end

  subgraph ARGO[argocd namespace]
    ac[argocd-application-controller]
    as[argocd-server]
    ar[argocd-repo-server]
    ad[argocd-dex]
  end
```

## 7. Reference URLs

- Prometheus docs: <https://prometheus.io/docs/introduction/overview/>
- Grafana docs: <https://grafana.com/docs/grafana/latest/>
- Loki docs: <https://grafana.com/docs/loki/latest/>
- Alloy docs: <https://grafana.com/docs/alloy/latest/>
- Argo CD docs: <https://argo-cd.readthedocs.io/en/stable/>
- kube-prometheus-stack chart: <https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack>
