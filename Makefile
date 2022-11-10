# https://makefiletutorial.com/

-include .env

### Helm routines
###
HELM_ARGS := --set "config.api.token=$(WALLARM_API_TOKEN)" \
			--set "config.api.host=$(WALLARM_API_HOST)" \
			--set "config.api.caVerify=$(WALLARM_API_CA_VERIFY)"

ifdef WALLARM_NODE_IMAGE
HELM_ARGS += \
			--set "aggregation.image.fullname=$(WALLARM_NODE_IMAGE)" \
			--set "processing.image.fullname=$(WALLARM_NODE_IMAGE)"
endif

helm-template:
	helm template wallarm-oob . -f values.yaml $(HELM_ARGS) --debug

helm-install:
	helm upgrade --install wallarm-oob . -f values.yaml $(HELM_ARGS) --debug

helm-uninstall:
	helm uninstall wallarm-oob

.PHONY: helm-*
