SHELL := /bin/bash

GIT_VERSION         ?= v0.1.0
GIT_MODULE          ?= opendev.org/airship/hostconfig-operator/pkg/version

# docker image options
DOCKER_REGISTRY     ?= quay.io
DOCKER_FORCE_CLEAN  ?= true
DOCKER_IMAGE_NAME   ?= hostconfig-operator
DOCKER_IMAGE_PREFIX ?= airshipit
DOCKER_IMAGE_TAG    ?= latest
DOCKER_IMAGE        ?= $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_PREFIX)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

# proxy options
PROXY               ?= http://proxy.foo.com:8000
NO_PROXY            ?= localhost,127.0.0.1,.svc.cluster.local
USE_PROXY           ?= false

# docker image publish
PUBLISH             ?= false

# Build hostconfig-operator image
.PHONY: images
images:
ifeq ($(USE_PROXY), true)
	@docker build . --tag $(DOCKER_IMAGE) \
                --build-arg http_proxy=$(PROXY) \
                --build-arg https_proxy=$(PROXY) \
                --build-arg HTTP_PROXY=$(PROXY) \
                --build-arg HTTPS_PROXY=$(PROXY) \
                --build-arg no_proxy=$(NO_PROXY) \
                --build-arg NO_PROXY=$(NO_PROXY) \
            --force-rm=$(DOCKER_FORCE_CLEAN)
else
	@docker build . --tag $(DOCKER_IMAGE) \
            --force-rm=$(DOCKER_FORCE_CLEAN)
endif
# Publishing hostconfig-operator image to quay.io
ifeq ($(PUBLISH), true)
	@echo 'publish hostconfig image to quay.io with image name $(DOCKER_IMAGE)'
	@docker push $(DOCKER_IMAGE)
endif

# Priniting docker image tag
.PHONY: print-docker-image-tag
print-docker-image-tag:
	@echo "$(DOCKER_IMAGE)"
