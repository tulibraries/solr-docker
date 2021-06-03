#Defaults
include .env
export #exports the .env variables

#Set DOCKER_IMAGE_VERSION in the .env file OR by passing in
VERSION ?= $(DOCKER_IMAGE_VERSION)
IMAGE ?= tulibraries/tul-solr
HARBOR ?= harbor.k8s.temple.edu
CLEAR_CACHES ?= no
CI ?= false
DEFAULT_RUN_ARGS ?= -e "EXECJS_RUNTIME=Disabled" \
		-e "K8=yes" \
		--rm -it

build:
	@docker build  \
		--tag $(HARBOR)/$(IMAGE):$(VERSION) \
		--tag $(HARBOR)/$(IMAGE):latest \
		--file .docker/solr/Dockerfile.solr \
		--no-cache .

run:
	@docker run --name=tul-solr -p 127.0.0.1:8983:8983/tcp \
		$(DEFAULT_RUN_ARGS) \
		$(HARBOR)/$(IMAGE):$(VERSION)

lint:
	@if [ $(CI) == false ]; \
		then \
			hadolint .docker/solr/Dockerfile.solr; \
		fi

shell:
	@docker run --rm -it \
		$(DEFAULT_RUN_ARGS) \
		--entrypoint=sh --user=root \
		$(HARBOR)/$(IMAGE):$(VERSION)

scan:
	@if [ $(CLEAR_CACHES) == yes ]; \
		then \
			trivy image -c $(HARBOR)/$(IMAGE):$(VERSION); \
		fi
	@if [ $(CI) == false ]; \
		then \
			trivy $(HARBOR)/$(IMAGE):$(VERSION); \
		fi

deploy: scan lint
	@docker push $(HARBOR)/$(IMAGE):$(VERSION) \
	# This "if" statement needs to be a one liner or it will fail.
	# Do not edit indentation
	@if [ $(VERSION) != latest ]; \
		then \
			docker push $(HARBOR)/$(IMAGE):latest; \
		fi
