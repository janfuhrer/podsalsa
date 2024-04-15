# syntax=docker/dockerfile:1

# include build-time dependencies to sbom
ARG BUILDKIT_SBOM_SCAN_CONTEXT=true

# define default values for build arguments
ARG BASE_IMAGE_BUILDER=golang
ARG GO_VERSION=1.22
ARG BUILD_DATE="1970-01-01T00:00:00Z"
ARG VERSION="v0.0.0-dev.0"
ARG COMMIT_REF="no-ref"
## use following two commands to get the latest digest with valid signature
# cosign verify gcr.io/distroless/static:nonroot --certificate-oidc-issuer https://accounts.google.com --certificate-identity keyless@distroless.iam.gserviceaccount.com
# cosign triangulate gcr.io/distroless/static:nonroot | cut -d'-' -f2 | cut -d'.' -f1
ARG DISTROLESS_DIGEST=f41b84cda410b05cc690c2e33d1973a31c6165a2721e2b5343aab50fecb63441

# builder
FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE_BUILDER}:${GO_VERSION}-alpine AS builder
WORKDIR /build
COPY go.mod go.sum main.go ./
COPY pkg/ ./pkg/
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETPLATFORM} go build \
  -ldflags "-s -w -X main.Version=${VERSION} -X main.Commit=${COMMIT_REF} -X main.CommitDate=${BUILD_DATE}" \
  -o podsalsa

# final image (see https://github.com/GoogleContainerTools/distroless)
FROM gcr.io/distroless/static:nonroot@sha256:${DISTROLESS_DIGEST}

# re-set ARG as we are in a new scope
ARG BUILD_DATE
ARG VERSION
ARG COMMIT_REF
ARG DISTROLESS_DIGEST

# set labels according to https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL \
  org.opencontainers.image.created=${BUILD_DATE} \
  org.opencontainers.image.authors="janfuhrer@mailbox.org" \
  org.opencontainers.image.url="https://github.com/janfuhrer/podsalsa" \
  org.opencontainers.image.documentation="https://github.com/janfuhrer/podsalsa" \
  org.opencontainers.image.source="https://github.com/janfuhrer/podsalsa" \
  org.opencontainers.image.version=${VERSION} \
  org.opencontainers.image.revision=${COMMIT_REF} \
  org.opencontainers.image.vendor="janfuhrer" \
  org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.title="Podsalsa" \
  org.opencontainers.image.description="Sample application to demonstrate supply chain security." \
  org.opencontainers.image.base.name="gcr.io/distroless/static:nonroot" \
  org.opencontainers.image.base.digest=${DISTROLESS_DIGEST}

WORKDIR /
COPY --from=builder /build/podsalsa .
COPY ./ui ./ui
USER nonroot:nonroot

ENTRYPOINT ["/podsalsa"]
