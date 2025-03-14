# Security Policy

## Reporting Security Issues

The contributor and community take security bugs in PodSalsa seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

To report a security issue, please use the GitHub Security Advisory ["Report a Vulnerability"](https://github.com/janfuhrer/podsalsa/security/advisories/new) tab.

The contributor will send a response indicating the next steps in handling your report. After the initial reply to your report, the security team will keep you informed of the progress towards a fix and full announcement, and may ask for additional information or guidance.

## Release verification

The release workflow creates provenance for its builds using the [SLSA standard](https://slsa.dev), which conforms to the [Level 3 specification](https://slsa.dev/spec/v1.0/levels#build-l3). The provenance is stored in the `multiple.intoto.jsonl` file of each release and can be used to verify the integrity and authenticity of the release artifacts.

All signatures are created by [Cosign](https://github.com/sigstore/cosign) using the [keyless signing](https://docs.sigstore.dev/verifying/verify/#keyless-verification-using-openid-connect) method. An overview how the keyless signing works can be found [here](./docs/slsa/sigstore/).

### Prerequisites

To verify the release artifacts, you will need the [slsa-verifier](https://github.com/slsa-framework/slsa-verifier), [cosign](https://github.com/sigstore/cosign) and [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) binaries. See the [prerequisites verification](docs/slsa/prerequisites-verification.md) for installation instructions.

### Version

All of the following commands require the `VERSION` environment variable to be set to the version of the release you want to verify. You can set the variable manually or the the latest version with the following command:

```bash
# get the latest release
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
```

### Inspect provenance

You can manually inspect the provenance of the release artifacts (without containers) by decoding the `multiple.intoto.jsonl` file.

```bash
# download the provenance file
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/multiple.intoto.jsonl

# decode the payload
cat multiple.intoto.jsonl | jq -r '.dsseEnvelope.payload' | base64 -d | jq
```

### Verify provenance of release artifacts

To verify the release artifacts (go binaries and SBOMs) you can use the `slsa-verifier`. This verification works for all release artifacts (`*.tar.gz`, `*.zip`, `*.sbom.json`).

```bash
# example for the "podsalsa-darwin-amd64.tar.gz" artifact
export ARTIFACT=podsalsa_${VERSION}_darwin_amd64.tar.gz

# download the artifact
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/$ARTIFACT

# download the provenance file
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/multiple.intoto.jsonl

# verify the artifact
slsa-verifier verify-artifact \
  --provenance-path multiple.intoto.jsonl \
  --source-uri github.com/janfuhrer/podsalsa \
  --source-tag $VERSION \
  $ARTIFACT
```

The output should be: `PASSED: Verified SLSA provenance`.

### Verify provenance of container images

**Verify with SLSA verifier**

The `slsa-verifier` can also verify docker images. Verification can be done by tag or by digest. We recommend to always use the digest to prevent [TOCTOU attacks](https://github.com/slsa-framework/slsa-verifier?tab=readme-ov-file#toctou-attacks), as an image tag is not immutable.

```bash
IMAGE=ghcr.io/janfuhrer/podsalsa:$VERSION

# get the image digest and append it to the image name
#   e.g. ghcr.io/janfuhrer/podsalsa:v0.2.0@sha256:...
IMAGE="${IMAGE}@"$(crane digest "${IMAGE}")

# verify the image
slsa-verifier verify-image \
  --source-uri github.com/janfuhrer/podsalsa \
  --provenance-repository ghcr.io/janfuhrer/signatures \
  --source-versioned-tag $VERSION \
  $IMAGE
```

The output should be: `PASSED: Verified SLSA provenance`.

**Verify with Cosign**

As an alternative to the SLSA verifier, you can use `cosign` to verify the provenance of the container images. Cosign also supports validating the attestation against `CUE` policies (see [Validate In-Toto Attestation](https://docs.sigstore.dev/verifying/attestation/#validate-in-toto-attestations) for more information), which is useful to ensure that some specific requirements are met. We provide a [policy.cue](./policy.cue) file to verify the correct workflow has triggered the release and that the image was generated from the correct source repository. 

```bash
# download policy.cue
curl -L -O https://raw.githubusercontent.com/janfuhrer/podsalsa/main/policy.cue

# verify the image with cosign
COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures cosign verify-attestation \
  --type slsaprovenance \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
  --policy policy.cue \
  $IMAGE | jq -r '.payload' | base64 -d | jq
```

Example output:

```bash
will be validating against CUE policies: [policy.cue]

Verification for ghcr.io/janfuhrer/podsalsa:v0.6.2@sha256:d6eaa2ae653ee894e7c1bb0e27d50bc94cb65ac65ace5daa8818ff0a30879cbc --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Certificate subject: https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v2.1.0
Certificate issuer URL: https://token.actions.githubusercontent.com
GitHub Workflow Trigger: push
GitHub Workflow SHA: b0e7f0a52697533f31ed6d8c6c3fa813449bff88
GitHub Workflow Name: goreleaser
GitHub Workflow Repository: janfuhrer/podsalsa
GitHub Workflow Ref: refs/tags/v0.6.2
{
  "_type": "https://in-toto.io/Statement/v0.1",
(...)
```

### Verify signature of container image

The container images are additionally signed with cosign. The signature can be verified with the `cosign` binary.
**Important**: only the multi-arch image is signed, not the individual platform images.

```bash
COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  $IMAGE | jq
```

Example output:

```bash
Verification for ghcr.io/janfuhrer/podsalsa@sha256:d6eaa2ae653ee894e7c1bb0e27d50bc94cb65ac65ace5daa8818ff0a30879cbc --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
[
  {
    "critical": {
(...)
```

If you want to see the entire certificate of the signature, you can use the following command:

```bash
COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  $IMAGE | jq -r '.[].optional.Bundle.Payload.body' | \
  base64 -d | jq -r '.spec.signature.publicKey.content' | \
  base64 -d | openssl x509 -text -noout
```

> [!IMPORTANT]
> Verifying the provenance of a container image ensures the integrity and authenticity of the image because the provenance (with the image digest) is signed with Cosign. The container images themselves are also signed with Cosign, but the signature is not necessary for verification if the provenance is verified. Provenance verification is a stronger security guarantee than image signing because it verifies the entire build process, not just the final image. Image signing is therefore not essential if provenance verification is.

### Verify signature of checksum file

Since all release artifacts can be verified with the `slsa-verifier`, a checksum file is not necessary (the integrity is already verified by the SLSA Verifier). A use case might be to verify the integrity of downloaded files and only rely only on Cosign instead of the SLSA verifier.

The checksum file can be verified with `cosign` as follows:

```bash
# download the checksum
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt

# verify the checksum file
cosign verify-blob \
	--certificate https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt.pem \
	--signature https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt.sig \
	--certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
	--certificate-oidc-issuer https://token.actions.githubusercontent.com \
	checksums.txt
```

The output should be: `Verified OK`.

### SBOM

The Software Bill of Materials (SBOM) is generated in CycloneDX JSON format for each release and can be used to verify the project's dependencies.

#### Go binary archives

The SBOMs of the Go binary archives are provided in the `*.tar.gz.sbom.json` files of the release and can be verified using the `slsa-verifier` (see [Verify the provenance of release artifacts](#verify-provenance-of-release-artifacts)).

#### Container images

The SBOMs of the container is attestated with Cosign and uploaded to the `ghcr.io/janfuhrer/sbom` repository. The SBOMs can be verified with the `cosign` binary.

**Important**: Only the multi-arch image has a SBOM, not the individual platform images.

**Verify provenance of the SBOM**

```bash
# download policy-sbom.cue
curl -L -O https://raw.githubusercontent.com/janfuhrer/podsalsa/main/policy-sbom.cue

COSIGN_REPOSITORY=ghcr.io/janfuhrer/sbom cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  --policy policy-sbom.cue \
  $IMAGE | jq -r '.payload' | base64 -d | jq
```

Example output:

```bash
will be validating against CUE policies: [policy-sbom.cue]

Verification for ghcr.io/janfuhrer/podsalsa:v0.6.2@sha256:d6eaa2ae653ee894e7c1bb0e27d50bc94cb65ac65ace5daa8818ff0a30879cbc --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Certificate subject: https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v0.6.2
Certificate issuer URL: https://token.actions.githubusercontent.com
GitHub Workflow Trigger: push
GitHub Workflow SHA: b0e7f0a52697533f31ed6d8c6c3fa813449bff88
GitHub Workflow Name: goreleaser
GitHub Workflow Repository: janfuhrer/podsalsa
GitHub Workflow Ref: refs/tags/v0.6.2
{
  "_type": "https://in-toto.io/Statement/v0.1",
(...)
```

**Download SBOM**

If you want to download the SBOM of the container image, you can use the following command:

```bash
COSIGN_REPOSITORY=ghcr.io/janfuhrer/sbom cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  --policy policy-sbom.cue \
  $IMAGE | jq -r '.payload' | base64 -d | jq -r '.predicate' > sbom.json
```

### Rekor

How to communicate with the Rekor transparency log directly is described in the [Rekor documentation](docs/slsa/sigstore/rekor.md).
