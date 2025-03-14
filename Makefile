NAME       ?= podsalsa
BUILD_DATE ?= $(shell date -Iseconds)
VERSION    ?= $(shell git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD)-local
# Adds "-dirty" suffix if there are uncommitted changes in the git repository
COMMIT_REF ?= $(shell git describe --dirty --always)
GOOS       ?= $(shell go env GOOS)
GOARCH     ?= $(shell go env GOARCH)

#########
# Go    #
#########

.PHONY: go-tidy
go-tidy:
	go mod tidy -compat=1.24
	@echo "Go modules tidied."

.PHONY: go-lint
go-lint:
	golangci-lint run
	@echo "Go lint completed."

.PHONY: go-update
go-update:
	go get -u ./...
	make go-tidy
	@echo "Go modules updated."

.PHONY: go-build
go-build:
	go build -o $(NAME) -trimpath -tags="netgo" -ldflags "-s -w -X main.Version=$(VERSION) -X main.Commit=$(COMMIT_REF) -X main.BuildTime=$(BUILD_DATE)" main.go
	@echo "Go build completed."

#########
# TOOLS #
#########

# https://github.com/ko-build/ko/releases
KO_VERSION  = v0.17.1
KO = $(shell pwd)/bin/ko

ko:
	$(call go-install-tool,$(KO),github.com/google/ko@$(KO_VERSION))

#########
# Ko    #
#########

KO_PLATFORM  ?= linux/$(GOARCH)
KOCACHE      ?= /tmp/ko-cache
KO_TAGS      := $(VERSION)

# Function to check if VERSION contains "-local" or "-rc*"
ifeq ($(findstring -local,$(VERSION)),)
  ifeq ($(findstring -rc,$(VERSION)),)
    # If VERSION does not contain "-local" or "-rc*", add 'latest' to KO_TAGS
    KO_TAGS := $(VERSION),latest
  endif
endif

REGISTRY        ?= ghcr.io
REPO            ?= janfuhrer
KO_REPOSITORY   := $(REGISTRY)/$(REPO)/$(NAME)

REGISTRY_PASSWORD  ?= dummy
REGISTRY_USERNAME  ?= dummy

LD_FLAGS        := "-s \
					-w \
					-X main.Version=$(VERSION) \
					-X main.Commit=$(COMMIT_REF) \
					-X main.BuildTime=$(BUILD_DATE)"

LABELS		    := "--image-label=org.opencontainers.image.created=$(BUILD_DATE),$\
						org.opencontainers.image.authors=janfuhrer@mailbox.org,$\
						org.opencontainers.image.url=https://github.com/janfuhrer/podsalsa,$\
						org.opencontainers.image.documentation=https://github.com/janfuhrer/podsalsa,$\
						org.opencontainers.image.source=https://github.com/janfuhrer/podsalsa,$\
						org.opencontainers.image.version=$(VERSION),$\
						org.opencontainers.image.revision=$(COMMIT_REF),$\
						org.opencontainers.image.vendor=janfuhrer,$\
						org.opencontainers.image.licenses=Apache-2.0,$\
						org.opencontainers.image.title=Podsalsa,$\
						org.opencontainers.image.description=Sample application to demonstrate supply chain security,$\
						org.opencontainers.image.base.name=cgr.dev/chainguard/static"

# Local ko build
.PHONY: ko-build-local
ko-build-local: ko
	@echo Building Podsalsa $(KO_TAGS) for $(KO_PLATFORM) >&2
	@LD_FLAGS=$(LD_FLAGS) KOCACHE=$(KOCACHE) KO_DOCKER_REPO=$(KO_REPOSITORY) \
		$(KO) build ./ --bare --tags=$(KO_TAGS) $(LABELS) --push=false --local --platform=$(KO_PLATFORM) --sbom=none

# Ko publish image
.PHONY: ko-login
ko-login: ko
	@$(KO) login $(REGISTRY) --username $(REGISTRY_USERNAME) --password $(REGISTRY_PASSWORD)

.PHONY: ko-publish-podsalsa
ko-publish-podsalsa: ko-login
	@LD_FLAGS=$(LD_FLAGS) KOCACHE=$(KOCACHE) KO_DOCKER_REPO=$(KO_REPOSITORY) \
		$(KO) build ./ --bare --tags=$(KO_TAGS) $(LABELS) --sbom=none

###########
# Helpers #
###########

# go-install-tool will 'go install' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-install-tool
@[ -f $(1) ] || { \
set -e ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
}
endef
