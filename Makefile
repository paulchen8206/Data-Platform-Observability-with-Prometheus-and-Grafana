COMPOSE ?= docker compose
TOPIC ?= platform-events
HELM ?= helm
KUBECTL ?= kubectl
K8S_NAMESPACE ?= monitoring
K8S_REQUIRED_SECRETS ?= grafana-admin
ARGOCD_NAMESPACE ?= argocd
ARGOCD_REPO_URL ?= $(shell git config --get remote.origin.url)
MINIKUBE_PROFILE ?= minikube
MINIKUBE_DRIVER ?= docker
GRAFANA_ADMIN_USER ?= admin
GRAFANA_ADMIN_PASSWORD ?= admin
ALLOY_CHART_VERSION ?= 1.7.0
ROUTINE ?= docker
ROUTINES := docker helm argocd

CORE_SERVICES := zookeeper kafka kafka-init schema-registry minio minio-init spark-master spark-worker producer spark-extraction kafka-ui
MONITORING_SERVICES := prometheus alertmanager grafana loki alloy kafka-exporter cadvisor node-exporter

.PHONY: help routine-list validate-routine \
	routine-up routine-down routine-status \
	routine-up-docker routine-up-helm routine-up-argocd \
	routine-down-docker routine-down-helm routine-down-argocd \
	routine-status-docker routine-status-helm routine-status-argocd \
	up build up-core up-monitoring down down-v restart ps \
	logs logs-producer logs-spark logs-alloy logs-prometheus logs-loki logs-cadvisor \
	verify-iceberg verify-warehouse-k8s rules-prometheus rules-loki check-loki check-kafka-alert-series health \
	kafka-topics kafka-consumer-groups spark-rebuild reset-checkpoints monitoring-recreate \
	k8s-minikube-start k8s-build-images k8s-local-prepare k8s-bootstrap-local k8s-up-argocd-local \
	k8s-preflight k8s-repo-setup k8s-grafana-install k8s-grafana-upgrade k8s-grafana-uninstall \
	k8s-stack-install k8s-stack-upgrade k8s-stack-uninstall \
	k8s-core-install k8s-up-helm-local k8s-argocd-install k8s-argocd-bootstrap k8s-argocd-password

help:
	@echo "Local Development (Docker Compose)"
	@echo ""
	@echo "Docker Routine"
	@echo "  make routine-up-docker      Start local Docker Compose stack"
	@echo "  make routine-status-docker  Show Docker Compose health"
	@echo "  make routine-down-docker    Stop Docker Compose stack"
	@echo "  Quickstart: make routine-up-docker && make routine-status-docker"
	@echo ""
	@echo "Kubernetes Routine (Helm)"
	@echo "  make routine-up-helm        Start Minikube + Helm flow"
	@echo "  make routine-status-helm    Show Kubernetes health on Minikube"
	@echo "  make routine-down-helm      Stop Minikube profile"
	@echo "  Quickstart: make routine-up-helm && make routine-status-helm"
	@echo ""
	@echo "Kubernetes Routine (Argo CD)"
	@echo "  make routine-up-argocd      Start Minikube + Argo CD flow"
	@echo "  make routine-status-argocd  Show Kubernetes + Argo CD health on Minikube"
	@echo "  make routine-down-argocd    Stop Minikube profile"
	@echo "  Quickstart: make routine-up-argocd && make routine-status-argocd"
	@echo ""
	@echo "Compatibility wrappers"
	@echo "  make routine-up ROUTINE=<docker|helm|argocd>"
	@echo "  make routine-down ROUTINE=<docker|helm|argocd>"
	@echo "  make routine-status ROUTINE=<docker|helm|argocd>"
	@echo ""
	@echo "Lifecycle"
	@echo "  make up                Build and start all services"
	@echo "  make build             Build all images"
	@echo "  make up-core           Start core data services"
	@echo "  make up-monitoring     Start monitoring/logging services"
	@echo "  make down              Stop and remove containers"
	@echo "  make down-v            Stop and remove containers, volumes, and orphans"
	@echo "  make restart           Restart all services"
	@echo "  make ps                Show service status"
	@echo ""
	@echo "Logs"
	@echo "  make logs              Tail all service logs"
	@echo "  make logs-producer     Tail producer logs"
	@echo "  make logs-spark        Tail spark-extraction logs"
	@echo "  make logs-alloy        Tail Alloy logs"
	@echo "  make logs-prometheus   Tail Prometheus logs"
	@echo "  make logs-loki         Tail Loki logs"
	@echo "  make logs-cadvisor     Tail cAdvisor logs"
	@echo ""
	@echo "Validation"
	@echo "  make health                    Run quick platform checks"
	@echo "  make verify-iceberg            Run Iceberg verification query"
	@echo "  make verify-warehouse-k8s      Print Iceberg row count and latest parquet files (k8s)"
	@echo "  make rules-prometheus          Show Prometheus alert rules"
	@echo "  make rules-loki                Show Loki ruler rules"
	@echo "  make check-loki                Check Loki labels and sample docker logs"
	@echo "  make check-kafka-alert-series  Check lag series for TOPIC"
	@echo "  make kafka-topics              List Kafka topics"
	@echo "  make kafka-consumer-groups     List Kafka consumer groups"
	@echo ""
	@echo "Maintenance"
	@echo "  make spark-rebuild      Rebuild and restart spark-extraction"
	@echo "  make reset-checkpoints  Remove Spark checkpoints except .gitkeep"
	@echo "  make monitoring-recreate Recreate monitoring/logging services"
	@echo ""
	@echo "Kubernetes (Production-like local)"
	@echo "  make k8s-preflight      Validate kubectl context, namespace, and required secrets"
	@echo "  make k8s-repo-setup      Add/update Helm repos"
	@echo "  make k8s-grafana-install Install Grafana (official chart)"
	@echo "  make k8s-grafana-upgrade Upgrade Grafana release"
	@echo "  make k8s-grafana-uninstall Uninstall Grafana release"
	@echo "  make k8s-stack-install   Install kube-prometheus-stack"
	@echo "  make k8s-stack-upgrade   Upgrade kube-prometheus-stack"
	@echo "  make k8s-stack-uninstall Uninstall kube-prometheus-stack"
	@echo "  make k8s-core-install    Install data platform core chart"
	@echo "  make k8s-up-argocd-local One-command local Argo CD flow (minikube + image builds + Argo CD apps)"
	@echo "  make k8s-up-helm-local   One-command local Helm flow (minikube + image builds + installs)"
	@echo "  make k8s-argocd-install  Install Argo CD"
	@echo "  make k8s-argocd-bootstrap Apply Argo CD app-of-apps"
	@echo "  make k8s-argocd-password Show Argo CD admin initial password"

routine-list:
	@echo "Supported routines: $(ROUTINES)"

validate-routine:
	@if ! echo "$(ROUTINES)" | tr ' ' '\n' | grep -qx "$(ROUTINE)"; then \
		echo "ERROR: ROUTINE must be one of: $(ROUTINES)"; \
		exit 1; \
	fi

routine-up: validate-routine routine-up-$(ROUTINE)

routine-down: validate-routine routine-down-$(ROUTINE)

routine-status: validate-routine routine-status-$(ROUTINE)

routine-up-docker: up

routine-up-helm: k8s-up-helm-local

routine-up-argocd: k8s-up-argocd-local

routine-down-docker: down

routine-down-helm: k8s-minikube-stop

routine-down-argocd: k8s-minikube-stop

routine-status-docker:
	@echo "=== Docker Compose health ==="
	@$(COMPOSE) ps
	@echo
	@echo "=== Prometheus up targets (docker) ==="
	@curl -sf http://localhost:9090/api/v1/targets >/dev/null && echo "Prometheus API reachable" || echo "Prometheus API not reachable"

routine-status-helm:
	@echo "=== Kubernetes health (profile: $(MINIKUBE_PROFILE)) ==="
	@ctx=`$(KUBECTL) config current-context 2>/dev/null`; \
	if [ -z "$$ctx" ]; then \
		echo "Kubernetes context: not set"; \
		echo "Hint: run 'kubectl config use-context $(MINIKUBE_PROFILE)'"; \
		exit 1; \
	fi; \
	echo "Kubernetes context: $$ctx"
	@$(KUBECTL) cluster-info >/dev/null && echo "Kubernetes API reachable" || { echo "Kubernetes API not reachable"; exit 1; }
	@echo
	@echo "=== monitoring namespace pods ==="
	@$(KUBECTL) get pods -n $(K8S_NAMESPACE)
	@echo
	@echo "=== data-platform namespace pods ==="
	@$(KUBECTL) get pods -n data-platform

routine-status-argocd: routine-status-helm
	@echo
	@echo "=== argocd namespace pods ==="
	@$(KUBECTL) get pods -n $(ARGOCD_NAMESPACE)

up:
	$(COMPOSE) up -d --build

build:
	$(COMPOSE) build

up-core:
	$(COMPOSE) up -d $(CORE_SERVICES)

up-monitoring:
	$(COMPOSE) up -d $(MONITORING_SERVICES)

down:
	$(COMPOSE) down

down-v:
	$(COMPOSE) down -v --remove-orphans

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

logs-producer:
	$(COMPOSE) logs -f producer

logs-spark:
	$(COMPOSE) logs -f spark-extraction

logs-alloy:
	$(COMPOSE) logs -f alloy

logs-prometheus:
	$(COMPOSE) logs -f prometheus

logs-loki:
	$(COMPOSE) logs -f loki

logs-cadvisor:
	$(COMPOSE) logs -f cadvisor

verify-iceberg:
	$(COMPOSE) --profile verify run --rm iceberg-reader

verify-warehouse-k8s:
	@echo "=== Iceberg row count (latest snapshot metadata) ==="
	@$(KUBECTL) delete pod -n data-platform aws-count --ignore-not-found >/dev/null 2>&1 || true
	@$(KUBECTL) run aws-count -n data-platform --restart=Never --image=amazon/aws-cli:2.15.39 \
		--env=AWS_ACCESS_KEY_ID=minioadmin \
		--env=AWS_SECRET_ACCESS_KEY=minioadmin \
		--env=AWS_DEFAULT_REGION=us-east-1 \
		--command -- sh -lc 'set -e; \
			LATEST=$$(aws --endpoint-url http://minio:9000 s3 ls s3://platform-warehouse/iceberg/platform/platform_events/metadata/ | tr -s " " | cut -d" " -f4 | grep metadata.json | sort -V | tail -n 1); \
			COUNT=$$(aws --endpoint-url http://minio:9000 s3 cp s3://platform-warehouse/iceberg/platform/platform_events/metadata/$$LATEST - | tr -d "\n" | tr "," "\n" | grep "\"total-records\"" | tail -n 1 | cut -d":" -f2 | tr -d "\" }"); \
			echo "LATEST_METADATA=$$LATEST"; \
			echo "ROW_COUNT=$$COUNT"'
	@$(KUBECTL) wait -n data-platform --for=jsonpath='{.status.phase}'=Succeeded pod/aws-count --timeout=180s >/dev/null
	@$(KUBECTL) logs -n data-platform aws-count
	@$(KUBECTL) delete pod -n data-platform aws-count --ignore-not-found >/dev/null
	@echo
	@echo "=== Latest parquet files (top 20) ==="
	@$(KUBECTL) delete pod -n data-platform mc-verify --ignore-not-found >/dev/null 2>&1 || true
	@$(KUBECTL) run mc-verify -n data-platform --restart=Never --image=minio/mc:latest --command -- sh -lc '\
		mc alias set local http://minio:9000 minioadmin minioadmin >/dev/null && \
		mc ls --recursive local/platform-warehouse/iceberg/platform/platform_events/data | sort -r | head -n 20'
	@$(KUBECTL) wait -n data-platform --for=jsonpath='{.status.phase}'=Succeeded pod/mc-verify --timeout=120s >/dev/null
	@$(KUBECTL) logs -n data-platform mc-verify
	@$(KUBECTL) delete pod -n data-platform mc-verify --ignore-not-found >/dev/null

rules-prometheus:
	curl -s http://localhost:9090/api/v1/rules

rules-loki:
	curl -s http://localhost:3100/loki/api/v1/rules

check-loki:
	@echo '=== Alloy Status ==='
	$(COMPOSE) ps alloy
	@echo '=== Loki service labels ==='
	curl -sG http://localhost:3100/loki/api/v1/label/service/values
	@echo
	@echo '=== Broad stream query {job="docker"} ==='
	curl -sG http://localhost:3100/loki/api/v1/query --data-urlencode 'query={job="docker"}' --data-urlencode 'limit=20'
	@echo

check-kafka-alert-series:
	@echo "=== Configured topic ==="
	@echo "TOPIC=$(TOPIC)"
	@echo "=== Prometheus lag series for configured topic ==="
	curl -sG http://localhost:9090/api/v1/series --data-urlencode 'match[]=kafka_consumergroup_lag{topic="$(TOPIC)"}'
	@echo

health:
	@echo "=== Service status ==="
	$(COMPOSE) ps
	@echo
	@echo "=== Prometheus Kafka alert rules ==="
	curl -s http://localhost:9090/api/v1/rules | grep -E 'KafkaTopicNoEvents2m|KafkaConsumerLagHigh|data-platform-alerts|platform-events' || true
	@echo
	@echo "=== Loki service labels ==="
	curl -sG http://localhost:3100/loki/api/v1/label/service/values
	@echo
	@echo "=== Kafka topics ==="
	$(COMPOSE) exec -T kafka kafka-topics --bootstrap-server kafka:9092 --list
	@echo
	@echo "=== Kafka consumer groups ==="
	$(COMPOSE) exec -T kafka kafka-consumer-groups --bootstrap-server kafka:9092 --list

kafka-topics:
	$(COMPOSE) exec -T kafka kafka-topics --bootstrap-server kafka:9092 --list

kafka-consumer-groups:
	$(COMPOSE) exec -T kafka kafka-consumer-groups --bootstrap-server kafka:9092 --list

spark-rebuild:
	$(COMPOSE) up -d --build spark-extraction

reset-checkpoints:
	find spark-extraction/checkpoints -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} +

monitoring-recreate:
	$(COMPOSE) up -d --force-recreate cadvisor prometheus grafana loki alloy

k8s-repo-setup:
	$(HELM) repo add grafana https://grafana.github.io/helm-charts || true
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	$(HELM) repo update

k8s-preflight:
	@echo "=== Kubernetes preflight ==="
	@ctx=`$(KUBECTL) config current-context 2>/dev/null`; \
	if [ -z "$$ctx" ]; then \
		echo "ERROR: no active kubectl context found."; \
		echo "Hint: run 'kubectl config get-contexts' and select one with 'kubectl config use-context <name>'."; \
		exit 1; \
	fi; \
	echo "Context: $$ctx"
	@$(KUBECTL) cluster-info >/dev/null 2>&1 || { \
		echo "ERROR: cannot reach Kubernetes API server for current context."; \
		exit 1; \
	}
	@$(KUBECTL) auth can-i get namespaces >/dev/null 2>&1 || { \
		echo "ERROR: insufficient RBAC to list namespaces."; \
		exit 1; \
	}
	@$(KUBECTL) get namespace $(K8S_NAMESPACE) >/dev/null 2>&1 || { \
		echo "Namespace '$(K8S_NAMESPACE)' does not exist; creating it for preflight checks..."; \
		$(KUBECTL) create namespace $(K8S_NAMESPACE) >/dev/null; \
	}
	@$(KUBECTL) auth can-i get secrets -n $(K8S_NAMESPACE) >/dev/null 2>&1 || { \
		echo "ERROR: insufficient RBAC to read secrets in namespace '$(K8S_NAMESPACE)'."; \
		exit 1; \
	}
	@for s in $(K8S_REQUIRED_SECRETS); do \
		$(KUBECTL) -n $(K8S_NAMESPACE) get secret $$s >/dev/null 2>&1 || { \
			echo "ERROR: required secret '$$s' is missing in namespace '$(K8S_NAMESPACE)'."; \
			echo "Create it, for example:"; \
			echo "  kubectl -n $(K8S_NAMESPACE) create secret generic $$s --from-literal=admin-user=<user> --from-literal=admin-password=<password>"; \
			exit 1; \
		}; \
	done
	@echo "Preflight passed for namespace '$(K8S_NAMESPACE)'."

k8s-grafana-install: k8s-preflight k8s-repo-setup
	$(KUBECTL) create namespace $(K8S_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(HELM) upgrade --install grafana grafana/grafana \
		--namespace $(K8S_NAMESPACE) \
		-f k8s/values-grafana-prod.yaml

k8s-grafana-upgrade:
	$(HELM) upgrade grafana grafana/grafana \
		--namespace $(K8S_NAMESPACE) \
		-f k8s/values-grafana-prod.yaml

k8s-grafana-uninstall:
	$(HELM) uninstall grafana --namespace $(K8S_NAMESPACE)

k8s-stack-install: k8s-preflight k8s-repo-setup
	$(KUBECTL) create namespace $(K8S_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(HELM) upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
		--namespace $(K8S_NAMESPACE) \
		-f k8s/values-kube-prometheus-stack-prod.yaml

k8s-stack-upgrade:
	$(HELM) upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
		--namespace $(K8S_NAMESPACE) \
		-f k8s/values-kube-prometheus-stack-prod.yaml

k8s-stack-uninstall:
	$(HELM) uninstall kube-prometheus-stack --namespace $(K8S_NAMESPACE)

k8s-core-install: k8s-preflight
	$(KUBECTL) create namespace data-platform --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(HELM) upgrade --install data-platform-core ./k8s/helm/data-platform-core \
		--namespace data-platform

k8s-minikube-start:
	@echo "=== Starting minikube profile '$(MINIKUBE_PROFILE)' ==="
	minikube start -p $(MINIKUBE_PROFILE) --driver=$(MINIKUBE_DRIVER)
	$(KUBECTL) config use-context $(MINIKUBE_PROFILE)

k8s-minikube-stop:
	@echo "=== Stopping minikube profile '$(MINIKUBE_PROFILE)' ==="
	minikube stop -p $(MINIKUBE_PROFILE)

k8s-build-images:
	@echo "=== Building local images in minikube Docker ==="
	@eval $$(minikube -p $(MINIKUBE_PROFILE) docker-env) && \
		docker build -t data-platform-grafana-prometheus-producer:latest ./source-ingestion && \
		docker build --target spark-runtime -t data-platform-grafana-prometheus-spark-runtime:latest ./spark-extraction && \
		docker build -t data-platform-grafana-prometheus-spark-extraction:latest ./spark-extraction

k8s-local-prepare:
	@echo "=== Preparing namespaces and required secret ==="
	$(KUBECTL) create namespace data-platform --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create namespace $(K8S_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) -n $(K8S_NAMESPACE) get secret grafana-admin >/dev/null 2>&1 || \
		$(KUBECTL) -n $(K8S_NAMESPACE) create secret generic grafana-admin \
			--from-literal=admin-user=$(GRAFANA_ADMIN_USER) \
			--from-literal=admin-password=$(GRAFANA_ADMIN_PASSWORD)

k8s-bootstrap-local: k8s-minikube-start k8s-build-images k8s-local-prepare k8s-repo-setup

k8s-up-helm-local: k8s-bootstrap-local
	@echo "=== Installing Helm releases ==="
	$(MAKE) k8s-core-install
	$(MAKE) k8s-stack-install
	$(HELM) upgrade --install loki grafana/loki \
		--namespace $(K8S_NAMESPACE) \
		-f k8s/values-loki-prod.yaml
	$(HELM) upgrade --install alloy grafana/alloy \
		--namespace $(K8S_NAMESPACE) \
		--version $(ALLOY_CHART_VERSION) \
		-f k8s/values-alloy-k8s.yaml
	$(KUBECTL) apply -k k8s/observability
	@echo "=== Kubernetes pods ==="
	$(KUBECTL) get pods -n $(K8S_NAMESPACE)
	$(KUBECTL) get pods -n data-platform

k8s-up-argocd-local: k8s-bootstrap-local
	@echo "=== Installing and bootstrapping Argo CD ==="
	$(MAKE) k8s-argocd-install
	$(MAKE) k8s-argocd-bootstrap
	@echo "=== Kubernetes pods ==="
	$(KUBECTL) get pods -n $(ARGOCD_NAMESPACE)
	$(KUBECTL) get pods -n data-platform

k8s-argocd-install:
	$(KUBECTL) create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

k8s-argocd-bootstrap:
	@repo="$(ARGOCD_REPO_URL)"; \
	if [ -z "$$repo" ]; then \
		echo "ERROR: ARGOCD_REPO_URL is empty."; \
		echo "Set it explicitly, e.g. make k8s-argocd-bootstrap ARGOCD_REPO_URL=https://github.com/<org>/<repo>.git"; \
		exit 1; \
	fi; \
	echo "Bootstrapping Argo CD with repo $$repo"; \
	for f in argocd/project.yaml argocd/apps/core.yaml argocd/apps/monitoring.yaml argocd/apps/loki-app.yaml argocd/apps/alloy.yaml argocd/app-of-apps.yaml; do \
		sed "s|https://github.com/LOCAL/REPLACE-ME.git|$$repo|g" $$f | $(KUBECTL) apply -f -; \
	done

k8s-argocd-password:
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode; echo
