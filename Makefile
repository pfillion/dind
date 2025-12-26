SHELL = /bin/sh
.SUFFIXES:
.PHONY: help
.DEFAULT_GOAL := help

ifeq ($(MODE_LOCAL),true)
	GIT_CONFIG_GLOBAL := $(shell git config --global --add safe.directory /main/src > /dev/null)
endif

# Tools Version
CST_VERSION			:= 1.22.1

# Docker-dind Version
VERSION            := 29.1.3
VERSION_PARTS      := $(subst ., ,$(VERSION))

MAJOR              := $(word 1,$(VERSION_PARTS))
MINOR              := $(word 2,$(VERSION_PARTS))
MICRO              := $(word 3,$(VERSION_PARTS))

CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(MICRO)
CURRENT_VERSION_MINOR := $(MAJOR).$(MINOR)
CURRENT_VERSION_MAJOR := $(MAJOR)

DATE                = $(shell date -u +"%Y-%m-%dT%H:%M:%S")
COMMIT             := $(shell git rev-parse HEAD)
AUTHOR             := $(firstword $(subst @, ,$(shell git show --format="%aE" $(COMMIT))))

# Docker parameters
ROOT_FOLDER=$(shell pwd)
NS ?= pfillion
IMAGE_NAME ?= dind
CONTAINER_NAME ?= dind
CONTAINER_INSTANCE ?= default

help: ## Show the Makefile help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

version: ## Show all versionning infos
	@echo CST_VERSION="$(CST_VERSION)"
	@echo CURRENT_VERSION_MICRO="$(CURRENT_VERSION_MICRO)"
	@echo CURRENT_VERSION_MINOR="$(CURRENT_VERSION_MINOR)"
	@echo CURRENT_VERSION_MAJOR="$(CURRENT_VERSION_MAJOR)"
	@echo DATE="$(DATE)"
	@echo COMMIT="$(COMMIT)"
	@echo AUTHOR="$(AUTHOR)"

build: ## Build the image form Dockerfile
	docker build \
		--build-arg CST_VERSION=$(CST_VERSION) \
		--build-arg DATE=$(DATE) \
		--build-arg CURRENT_VERSION_MICRO=$(CURRENT_VERSION_MICRO) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg AUTHOR=$(AUTHOR) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MINOR) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MAJOR) \
		-t $(NS)/$(IMAGE_NAME):latest \
		-f Dockerfile .

push: ## Push the image to a registry
ifdef DOCKER_USERNAME
	@echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin
endif
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO)
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MINOR)
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MAJOR)
	docker push $(NS)/$(IMAGE_NAME):latest
    
shell: start ## Run shell command in the container
	docker exec -it $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/sh
	$(docker_stop)

start: ## Run the container in background
	docker run -d --rm --privileged --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO)

stop: ## Stop the container
	$(docker_stop)

test: ## Run all tests
	container-structure-test test \
		--image $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO) \
		--config tests/config.yaml

test-ci: ## Run CI pipeline locally
	woodpecker-cli exec --local --repo-trusted-volumes=true --env=MODE_LOCAL=true			

release: build push ## Build and push the image to a registry

define docker_stop
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)
endef