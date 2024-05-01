NAME := podsalsa
DOCKER_REPOSITORY := janfuhrer
DOCKER_IMAGE_NAME := $(DOCKER_REPOSITORY)/$(NAME)
BUILD_DATE := $(shell date -Iseconds)
VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD)-local
# Adds "-dirty" suffix if there are uncommitted changes in the git repository
COMMIT_REF:=$(shell git describe --dirty --always)
EXTRA_FLAGS ?=

# Base Docker build command
DOCKER_BUILDX_BASE = docker buildx build \
	--build-arg "BUILD_DATE=$(BUILD_DATE)" \
	--build-arg "VERSION=$(VERSION)" \
	--build-arg "COMMIT_REF=$(COMMIT_REF)" \
	-t $(DOCKER_IMAGE_NAME):$(VERSION) \
	$(EXTRA_FLAGS) .

.PHONY: go-tidy go-build docker-build docker-build-with-provenance

go-tidy:
	go mod tidy -compat=1.22
	@echo "Go modules tidied."

go-build:
	go build -o $(NAME) -trimpath -tags="netgo" -ldflags "-s -w -X main.Version=$(VERSION) -X main.Commit=$(COMMIT_REF) -X main.BuildTime=$(BUILD_DATE)" main.go
	@echo "Go build completed."

docker-build: EXTRA_FLAGS =
docker-build:
	$(DOCKER_BUILDX_BASE)
	@echo "Docker build completed."

# IMPORTANT: enable "containerd image store" in Docker Desktop settings
#            to use "--sbom" and "--provenance" flags
#            https://docs.docker.com/desktop/containerd/
docker-build-with-provenance: EXTRA_FLAGS = --sbom=true --provenance=true --output type=local,dest=out
docker-build-with-provenance:
	$(DOCKER_BUILDX_BASE)
	@echo "Docker build with SBOM and provenance completed."
