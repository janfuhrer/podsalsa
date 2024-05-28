# Archive

This directory contains not used files but that are kept for historical reasons.

## Policy controller (Kubernetes enforcement)

This repository [contains an example](../docs/slsa/enforcement-kubernetes/) of how to enforce SLSA verification on the podsalsa image using [Kyverno](https://kyverno.io/).
Another solution is to use Sigstore's [Policy Controller](https://docs.sigstore.dev/policy-controller/overview/). An example of such a policy is available in the file [policy-controller/clusterimagepolicy.yaml](policy-controller/clusterimagepolicy.yaml). As the Policy Controller is limited to SLSA verification only and is still under active development, it is more convenient to use Kyverno to enforce SLSA verification.

## SLSA GoReleaser Workflow

The [slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator) repository also provides a GitHub action workflow to build Go binaries and generate provenance metadata. More information can be found in the [README](https://github.com/slsa-framework/slsa-github-generator/blob/main/internal/builders/go/README.md).
Since we use the [GoReleaser](https://goreleaser.com/) to build the Go binaries, we use the [generic-generator](https://github.com/slsa-framework/slsa-github-generator/tree/main/internal/builders/generic/README.md) to generate the SLSA metadata.

The workflow is available in the [slsa-goreleaser](./slsa-goreleaser/) directory.

## Dockerfile

The [Dockerfile](./Dockerfile) provides a example to build a container image for the podsalsa application with Docker. The image is built using the [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/) and uses the [distroless](https://github.com/GoogleContainerTools/distroless) base image.

Since the container images are built using [ko](https://github.com/ko-build/ko), this Dockerfile is not used anymore.

## Makefile

The [Makefile](./Makefile) provides a set of commands to build the container image using the above Dockerfile with sbom and provenance.

## SBOM creation with ko

The first approach to creating SBOMs for the container images was to use `ko`. This approach does not sign the SBOMs and is therefore provides no integrity and authenticity guarantees. The configuration used is described in the file [ko-sbom.md](./ko-sbom.md).
