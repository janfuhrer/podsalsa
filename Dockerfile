# syntax=docker/dockerfile:1

# include build-time dependencies to sbom
ARG BUILDKIT_SBOM_SCAN_CONTEXT=true

ARG BASE_IMAGE=golang:1.22-alpine
ARG BASE_IMAGE_DIGEST=963da5f97ab931c0df6906e8c0ebc7db28c88d013735ae020f9558c3e6cf0580

# use following two commands to get the latest digest with valid signature
#     cosign verify gcr.io/distroless/static:nonroot --certificate-oidc-issuer https://accounts.google.com --certificate-identity keyless@distroless.iam.gserviceaccount.com
#     cosign triangulate gcr.io/distroless/static:nonroot | cut -d'-' -f2 | cut -d'.' -f1
ARG DISTROLESS_DIGEST=f41b84cda410b05cc690c2e33d1973a31c6165a2721e2b5343aab50fecb63441

# builder
FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE}@sha256:${BASE_IMAGE_DIGEST} AS builder

ARG BUILD_DATE
ARG VERSION
ARG COMMIT_REF

WORKDIR /build
COPY go.mod go.sum main.go ./
COPY pkg/ ./pkg/
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETPLATFORM} go build \
  -trimpath \
  -tags="netgo" \
  -ldflags "-s -w -X main.Version=${VERSION} -X main.Commit=${COMMIT_REF} -X main.BuildTime=${BUILD_DATE}" \
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
