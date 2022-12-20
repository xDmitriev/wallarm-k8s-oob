# https://makefiletutorial.com/

-include .env
.EXPORT_ALL_VARIABLES:

DIR = $(shell cd "$$( dirname "${BASH_SOURCE[0]}" )" && pwd )

KIND_CLUSTER_NAME ?= wallarm-oob
KIND_CLUSTER_VERSION ?= "v1.25.2"
KUBE_CONFIG  ?= "${HOME}/.kube/kind-config-${KIND_CLUSTER_NAME}"

KUBECTL_CMD  := KUBECONFIG=$(KUBE_CONFIG) kubectl
HELM_CMD     := KUBECONFIG=$(KUBE_CONFIG) helm

all: env-up helm-install smoke-test
.PHONY: all

env-up:
	kind create cluster \
			--name ${KIND_CLUSTER_NAME} \
			--image "kindest/node:${KIND_CLUSTER_VERSION}" \
			--kubeconfig ${KUBE_CONFIG} \
			--retain
	$(KUBECTL_CMD) apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml
	$(KUBECTL_CMD) patch -n kube-system deployment metrics-server --type=json \
       -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
	$(KUBECTL_CMD) get nodes -o wide

env-down:
	@kind delete cluster --name ${KIND_CLUSTER_NAME}

.PHONY: env-*

### Helm routines
###
HELM_EXTRA_ARGS +=
HELM_TEST_IMAGE += "quay.io/dmitriev/chart-testing:latest-amd64"
HELM_ARGS := --set "config.api.token=${WALLARM_API_TOKEN}" $(HELM_EXTRA_ARGS)

helm-template:
	$(HELM_CMD) template wallarm-oob ./helm $(HELM_ARGS) --debug

helm-install:
	$(HELM_CMD) upgrade --install wallarm-oob ./helm $(HELM_ARGS) --debug --wait
	$(KUBECTL_CMD) wait --for=condition=Ready pods --all --timeout=90s

helm-uninstall:
	$(HELM_CMD) uninstall wallarm-oob

helm-test:
	@docker run \
        --rm \
        --interactive \
        --network host \
        --name chart-testing \
        --volume ${KUBE_CONFIG}:/root/.kube/config \
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
