# Security Policy

## Reporting Security Issues

The contributor and community take security bugs in PodSalsa seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

To report a security issue, please use the GitHub Security Advisory ["Report a Vulnerability"](https://github.com/janfuhrer/podsalsa/security/advisories/new) tab.

The contributor will send a response indicating the next steps in handling your report. After the initial reply to your report, the security team will keep you informed of the progress towards a fix and full announcement, and may ask for additional information or guidance.

## Release verification

The release workflow creates provenance for its builds using the [SLSA standard](https://slsa.dev), which conforms to the [Level 3 specification](https://slsa.dev/spec/v1.0/levels#build-l3). The provenance is stored in the `multiple.intoto.jsonl` file of each release and can be used to verify the integrity and authenticity of the release artifacts.

All signatures are created by [Cosign](https://github.com/sigstore/cosign) using the [keyless signing](https://docs.sigstore.dev/verifying/verify/#keyless-verification-using-openid-connect) method.

### Prerequisites

To verify the release artifacts, you will need the [slsa-verifier](https://github.com/slsa-framework/slsa-verifier), [cosign](https://github.com/sigstore/cosign) and [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) binaries. See the [prerequisites verification](docs/prerequisites-verification.md) for installation instructions.

### Inspect provenance

You can manually inspect the provenance of the release artifacts by decoding the `multiple.intoto.jsonl` file.

```bash
# get the latest release
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

# download the provenance file
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/multiple.intoto.jsonl

# decode the payload
cat multiple.intoto.jsonl | jq -r '.payload' | base64 -d | jq
```

### Verify provenance of release artifacts

To verify the release artifacts (go binaries and SBOMs), you can use the `slsa-verifier`. This verification works for all release artifcats (`*.tar.gz`, `*.zip`, `*.sbom`).

```bash
# example for the "podsalsa-darwin-amd64.tar.gz" artifact
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
export ARTIFACT=podsalsa_$VERSION_darwin_amd64.tar.gz

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
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
IMAGE=ghcr.io/janfuhrer/podsalsa:$VERSION

# get the image digest and append it to the image name
#   e.g. ghcr.io/janfuhrer/podsalsa:v0.2.0@sha256:...
IMAGE="${IMAGE}@"$(crane digest "${IMAGE}")

# verify the image
slsa-verifier verify-image "$IMAGE" \
	--source-uri github.com/janfuhrer/podsalsa \
	--provenance-repository ghcr.io/janfuhrer/signatures \
	--source-versioned-tag $VERSION
```

The output should be: `PASSED: Verified SLSA provenance`.

**Verify with Cosign**

As an alternative to the SLSA Verifier, you can use `cosign` to verify the docker images. Cosign also supports validating the attestation against `CUE` policies (see [Validate In-Toto Attestation](https://docs.sigstore.dev/verifying/attestation/#validate-in-toto-attestations) for more information), which is useful to ensure that some specific requirements are met. We provide a [policy.cue](./policy.cue) file to verify the correct workflow has triggered the release and that the image was generated from the correct source repository. 

```bash
# download policy.cue
curl -L -O https://raw.githubusercontent.com/janfuhrer/podsalsa/main/policy.cue

# verify the image with cosign
COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures cosign verify-attestation \
  --type slsaprovenance \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
  --policy policy.cue \
  $IMAGE | jq
```

Example output:

```bash
will be validating against CUE policies: [policy.cue]

Verification for ghcr.io/janfuhrer/podsalsa:v0.3.1@sha256:e111e800dc80067d56499fe10fe1cc90eaf9e204658475b838cbad3db32cdff9 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Certificate subject: https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v2.0.0
Certificate issuer URL: https://token.actions.githubusercontent.com
GitHub Workflow Trigger: push
GitHub Workflow SHA: b646f50ebce3106be3942c4694b6e2f19042df22
GitHub Workflow Name: goreleaser
GitHub Workflow Repository: janfuhrer/podsalsa
GitHub Workflow Ref: refs/tags/v0.3.1
{
  "payloadType": "application/vnd.in-toto+json",
(...)
```

### Verify signature of container image

The container images are signed with Cosign. The signature can be verified with `cosign`.

```bash
COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures cosign verify \
  ghcr.io/janfuhrer/podsalsa:$VERSION \
  --type slsaprovenance \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workfows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' | jq
```

> [!IMPORTANT]
> Verifying the provenance of a container image ensure the integrity and authenticity of the image, since the provenance (with the image digest) is signed with Cosign. The container images themselves are also signed with Cosign, but the signature is not necessary for verification if the provenance is verified. The provenance verification is a stronger security guarantee than image signing because it verifies the entire build process, not just the final image. Image signing is therefore not necessary if provenance verification is.

### Verify signature of checksum file

Since all release artifacts can be verified with the `slsa-verifier`, a checksum file is not necessary (the integrity is already verified by the SLSA Verifier). A use case might be to verify the integrity of downloaded files and only rely on Cosign instead of the SLSA Verifier.

The checksum file can be verified with `cosign` as follows:

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

# download the checksum
curl -L -O https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt

# verify the checksum file
cosign verify-blob \
	--certificate https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt.pem \
	--signature https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/checksums.txt.sig \
	--certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
	--certificate-oidc-issuer https://token.actions.githubusercontent.com \
	checksums.txt
```

The output should be: `Verified OK`.

### SBOM

The Software Bill of Materials (SBOM) is generated in CycloneDX JSON format for each release and can be used to verify the dependencies of the project.

The SBOM of the Go binaries is available in the `*.sbom` files of the release and can be verified with the `slsa-verifier` (see [Verify Provenance of Release Artifacts](#verify-provenance-of-release-artifacts)).

The SBOMs of the container image can be downloaded with `cosign` or `crane`.

**Download SBOM of container with cosign**

You must specify the platform of the image to download the correct SBOM. As the SBOMs are stored in a separate repository, you have to specify the `COSIGN_REPOSITORY` environment variable to download the SBOM.

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
export PLATFORM="linux/amd64"

COSIGN_REPOSITORY=ghcr.io/janfuhrer/sbom cosign download sbom \
	ghcr.io/janfuhrer/podsalsa:$VERSION \
	--platform $PLATFORM | jq
```

The `cosign download sbom` command will be deprecated in the future. There are open issues in the [cosign repository](https://github.com/sigstore/cosign/issues/2307) to provide a better way to download the SBOM.

**Download SBOM of container with crane**

We can also use `crane` to download the SBOM of the container image. Since the SBOMs are stored in a slightly different format, we have to transform the digest of the image to the correct SBOM tag.

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
export PLATFORM="linux/amd64"

# get digest of a specific image tag
export SBOM_TAG=$(crane digest ghcr.io/janfuhrer/podsalsa:$VERSION --platform $PLATFORM | sed -E 's/sha256:([0-9a-f]+)/sha256-\1.sbom/')

# download SBOM
crane export ghcr.io/janfuhrer/sbom:$SBOM_TAG ./$SBOM_TAG
```
