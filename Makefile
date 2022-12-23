# https://makefiletutorial.com/

-include .env
.EXPORT_ALL_VARIABLES:

DIR = $(shell cd "$$( dirname "${BASH_SOURCE[0]}" )" && pwd )

KIND_CLUSTER_NAME ?= wallarm-oob
KUBECONFIG  ?= "${HOME}/.lima/k8s/conf/kubeconfig.yaml"

KUBECTL_CMD  := KUBECONFIG=$(KUBECONFIG) kubectl
HELM_CMD     := KUBECONFIG=$(KUBECONFIG) helm

all: env-up helm-install smoke-test
.PHONY: all

env-up:
	@limactl start --name k8s --tty=false template://k8s
	@limactl shell k8s sudo cat /etc/kubernetes/admin.conf > $(KUBECONFIG)
	$(KUECTL_CMD) get nodes

env-kubeconfig:
	@limactl shell k8s sudo cat /etc/kubernetes/admin.conf > $(KUBECONFIG)

env-stop:
	@limactl stop k8s

env-start:
	@limactl start k8s

env-down:
	@limactl delete k8s

.PHONY: env-*

### Helm routines
###
HELM_EXTRA_ARGS +=
HELM_TEST_IMAGE += "quay.io/dmitriev/chart-testing:latest-amd64"
HELM_ARGS := --set "config.api.token=${WALLARM_API_TOKEN}" $(HELM_EXTRA_ARGS)

helm-template:
	$(HELM_CMD) template wallarm-oob ./helm $(HELM_ARGS) --debug

helm-install:
	$(HELM_CMD) upgrade --install oob-ebpf ./helm $(HELM_ARGS) --wait
	$(KUBECTL_CMD) wait --for=condition=Ready pods --all --timeout=90s

helm-uninstall:
	$(HELM_CMD) uninstall wallarm-oob

helm-test:
	@docker run \
        --rm \
        --interactive \
        --network host \
        --name chart-testing \
        --volume ${KUBECONFIG}:/root/.kube/config \
        --volume ${DIR}:/workdir \
        --workdir /workdir \
        ${HELM_TEST_IMAGE} ct install \
            --charts helm \
            --helm-extra-set-args "${HELM_ARGS}" \
            --helm-extra-args "--timeout 90s" \
            ${CT_EXTRA_ARGS:-} \
            --debug

.PHONY: helm-*

smoke-test:  ## Run smoke tests (expects access to a working Kubernetes cluster).
	@test/smoke/run-smoke-suite.sh

.PHONY: smoke-test
