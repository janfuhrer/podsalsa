# Security Policy

## Reporting Security Issues

The contributor and community take security bugs in PodSalsa seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

To report a security issue, please use the GitHub Security Advisory ["Report a Vulnerability"](https://github.com/janfuhrer/podsalsa/security/advisories/new) tab.

The contributor will send a response indicating the next steps in handling your report. After the initial reply to your report, the security team will keep you informed of the progress towards a fix and full announcement, and may ask for additional information or guidance.

## Release verification

The release workflow creates provenance for its builds using the [SLSA standard](https://slsa.dev), which conforms to the [Level 3 specification](https://slsa.dev/spec/v1.0/levels#build-l3). The provenance is stored in the `multiple.intoto.jsonl` file of each release and can be used to verify the integrity and authenticity of the release artifacts.

All signatures are created by [Cosign](https://github.com/sigstore/cosign) using the [keyless signing](https://docs.sigstore.dev/verifying/verify/#keyless-verification-using-openid-connect) method.

### Prerequisites

To verify the release artifacts, you will need the [slsa-verifier](https://github.com/slsa-framework/slsa-verifier), [cosign](https://github.com/sigstore/cosign) and [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) binaries. See the [prerequisites verification](docs/prerequisites_verification.md) for installation instructions.

### Inspect Provenance

You can manually inspect the provenance of the release artifacts by decoding the `multiple.intoto.jsonl` file.

```bash
# get the latest release
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

# download the provenance file
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/multiple.intoto.jsonl

# decode the payload
cat multiple.intoto.jsonl | jq -r '.payload' | base64 -d | jq
```

### Verify Provenance of Release Artifacts

To verify the release artifacts (go binaries and SBOMs), you can use the `slsa-verifier`. This verification works for all release artifcats (`*.tar.gz`, `*.zip`, `*.sbom`).

```bash
# example for the "podsalsa-darwin-amd64.tar.gz" artifact
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
export ARTIFACT=podsalsa-darwin-amd64.tar.gz

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

Verifying artifact podsalsa-darwin-amd64.tar.gz: PASSED
PASSED: Verified SLSA provenance
```

### Verify Provenance of Container Images

The `slsa-verifier` can also verify docker images. Verification can be done by tag or by digest. We recommend to always use the digest to prevent [TOCTOU attacks](https://github.com/slsa-framework/slsa-verifier?tab=readme-ov-file#toctou-attacks), as an image tag is not immutable.

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
IMAGE=ghcr.io/janfuhrer/podsalsa:$VERSION

# get the image digest and append it to the image name
#   e.g. ghcr.io/janfuhrer/podsalsa:v0.2.0@sha256:...
IMAGE="${IMAGE}@"$(crane digest "${IMAGE}")

# verify the image
slsa-verifier verify-image "$IMAGE" \
	--source-uri github.com/janfuhrer/podsalsa \
	--source-versioned-tag $VERSION

PASSED: Verified SLSA provenance
```

As an alternative to the SLSA Verifier, you can use `cosign` to verify the docker images. Cosign also supports validating the attestation against `CUE` policies (see [Validate In-Toto Attestation](https://docs.sigstore.dev/verifying/attestation/#validate-in-toto-attestations) for more information), which is useful to ensure that some specific requirements are met. We provide a [policy.cue](./policy.cue) file to verify the correct workflow has triggered the release and that the image was generated from the correct source repository. 

```bash
# download policy.cue
curl -L -O https://raw.githubusercontent.com/janfuhrer/podsalsa/main/policy.cue

# verify the image with cosign
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
  --policy policy.cue \
  $IMAGE | jq
```

### Verify Signature of Checksum file

Since all release artifacts can be verified with the `slsa-verifier`, a checksum file is not necessary (the integrity is already verified by the SLSA Verifier). A use case might be to verify the integrity of downloaded files and only rely on Cosign instead of the SLSA Verifier.

The checksum file can be verified with `cosign` as follows:

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

# download the checksum, signature and certificate files
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt.sig
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt.pem

# verify the checksum file
cosign verify-blob \
	--certificate checksums.txt.pem \
	--signature checksums.txt.sig \
	--certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
	--certificate-oidc-issuer https://token.actions.githubusercontent.com \
	checksums.txt
```

### SBOM

The Software Bill of Materials (SBOM) is generated in CycloneDX JSON format for each release and can be used to verify the dependencies of the project.

The SBOM of the Go binaries is available in the `*.sbom` files of the release and can be verified with the `slsa-verifier` (see [Verify Provenance of Release Artifacts](#verify-provenance-of-release-artifacts)).

The SBOMs of the container image can be downloaded with `cosign`. You must specify the platform of the image to download the correct SBOM. As the SBOMs are stored in a separate repository, you have to specify the `COSIGN_REPOSITORY` environment variable to download the SBOM.

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

COSIGN_REPOSITORY=ghcr.io/janfuhrer/sbom cosign download sbom ghcr.io/janfuhrer/podsalsa:$VERSION --platform linux/arm64
```

The `cosign download sbom` command will be deprecated in the future. At the moment, I have not found another way to download the SBOM of the container images. There are open issues in the [cosign repository](https://github.com/sigstore/cosign/issues/2307) to provide a better way to download the SBOM.
