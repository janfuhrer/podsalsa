# Archive

Superseded approaches, kept for reference. Nothing here is part of the current release
pipeline — for that, start at [the documentation index](../docs/README.md).

> [!WARNING]
> Most of this directory predates the migration to [GitHub Artifact Attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations).
> The examples use the [slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator),
> which is no longer maintained, and match the SLSA **v0.2** predicate it produced.
> Do not copy these files into new projects.

## Contents

| File | What it is | Why it is archived |
| :--- | :--- | :--- |
| [verification-legacy.md](./verification-legacy.md) | Verifying releases up to **v0.9.x** with `slsa-verifier` | Still accurate for those releases; v0.10.0+ uses [`gh attestation verify`](../SECURITY.md#release-verification) |
| [policy-controller/](./policy-controller/) | Sigstore [Policy Controller](https://docs.sigstore.dev/policy-controller/overview/) `ClusterImagePolicy` | The Kubernetes example uses [Kyverno](../docs/slsa/enforcement-kubernetes/), which is not limited to SLSA verification |
| [slsa-goreleaser/](./slsa-goreleaser/) | The SLSA [Go builder](https://github.com/slsa-framework/slsa-github-generator/blob/main/internal/builders/go/README.md) workflow | Superseded by the [trusted builders](../.github/workflows/README.md#trusted-builders-and-slsa-build-level-3) |
| [ko-sbom.md](./ko-sbom.md) | The first approach to container SBOMs, using `ko` | It produced unsigned SBOMs, so it offered no integrity or authenticity guarantee. `cyclonedx-gomod` is used instead |
| [Dockerfile](./Dockerfile) | Multi-stage build on a [distroless](https://github.com/GoogleContainerTools/distroless) base | Images are built with [ko](https://ko.build/) |
| [Makefile](./Makefile) | Builds the image from the archived Dockerfile, with SBOM and provenance | Belongs to the archived Dockerfile |
