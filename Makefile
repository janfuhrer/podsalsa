NAME       ?= podsalsa
BUILD_DATE ?= $(shell date -Iseconds)
VERSION    ?= $(shell git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD)-local
# Full commit SHA, matching goreleaser's "{{ .Commit }}" so binaries and container
# images report the same value. Adds a "-dirty" suffix for uncommitted changes.
COMMIT_REF ?= $(shell git rev-parse HEAD)$(shell git diff --quiet HEAD 2>/dev/null || echo "-dirty")
GOOS       ?= $(shell go env GOOS)
GOARCH     ?= $(shell go env GOARCH)

#########
# Go    #
#########

.PHONY: go-tidy
go-tidy:
	go mod tidy -compat=1.27
	@echo "Go modules tidied."

.PHONY: go-test
go-test:
	go test -tags unit -race ./...
	@echo "Go tests completed."

# Fuzz targets are behind the same "unit" build tag as the rest of the tests.
FUZZTIME ?= 60s
FUZZ     ?= FuzzRouter
.PHONY: go-fuzz
go-fuzz:
	go test -tags unit -run '^$$' -fuzz $(FUZZ) -fuzztime $(FUZZTIME) ./pkg/http/
	@echo "Go fuzzing completed."

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
KO_VERSION  = v0.19.1
KO = $(shell pwd)/bin/ko

ko:
	$(call go-install-tool,$(KO),github.com/google/ko@$(KO_VERSION))

# https://github.com/CycloneDX/cyclonedx-gomod/releases
CYCLONEDX_GOMOD_VERSION = v1.12.0
CYCLONEDX_GOMOD = $(shell pwd)/bin/cyclonedx-gomod

cyclonedx-gomod:
	$(call go-install-tool,$(CYCLONEDX_GOMOD),github.com/CycloneDX/cyclonedx-gomod/cmd/cyclonedx-gomod@$(CYCLONEDX_GOMOD_VERSION))

# https://github.com/cue-lang/cue/releases
CUE_VERSION = v0.17.1
CUE = $(shell pwd)/bin/cue

cue:
	$(call go-install-tool,$(CUE),cuelang.org/go/cmd/cue@$(CUE_VERSION))

#########
# SBOM  #
#########

SBOM_NAME ?= $(NAME)
SBOM_MAIN ?= ./

# ko only emits a minimal SBOM, so the container SBOM is generated with cyclonedx-gomod
.PHONY: sbom-container
sbom-container: cyclonedx-gomod
	$(CYCLONEDX_GOMOD) app -licenses -json -output $(SBOM_NAME)-bom.cdx.json -main $(SBOM_MAIN)
	@echo "SBOM written to $(SBOM_NAME)-bom.cdx.json"

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
