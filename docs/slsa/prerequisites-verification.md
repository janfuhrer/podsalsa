# Prerequisites verification

## GitHub CLI

The provenance of podsalsa releases is generated with [GitHub Artifact Attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) and verified with the [GitHub CLI](https://cli.github.com/) (`gh attestation verify`). Version 2.49.0 or newer is required.

Download with Homebrew:

```bash
brew install gh
```

For other platforms see the [installation instructions](https://github.com/cli/cli#installation). Authenticate once with `gh auth login`, which is also what lets `gh` pull attestations for images from a private registry.

## CUE

[CUE](https://cuelang.org/) is used to validate the *contents* of the provenance against [policy.cue](../../policy.cue), which is the complement to the signer-identity check that `gh attestation verify` performs.

```bash
brew install cue
```

## SLSA-Verifier (legacy releases only)

Releases up to and including **v0.9.x** were built with the now-deprecated [slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator) and are verified with the [slsa-verifier](https://github.com/slsa-framework/slsa-verifier) instead of `gh`. You only need this tool to verify those older releases — see [Legacy verification](../../archive/verification-legacy.md).

```bash
brew install slsa-verifier
```

## Cosign

The [Cosign](https://github.com/sigstore/cosign) CLI verifies the image signature, the SBOM attestation and the checksum file.

Install Cosign via Homebrew or have a look at the [installation instructions](https://docs.sigstore.dev/system_config/installation/).

```bash
brew install cosign
```

## Crane

[Crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) is a tool for interacting with remote images and registries. We use it to get the image digest for the verification.

Download with Hombrew:

```bash
brew install crane
```

Download binary from GitHub and verify SLSA provenance:

```bash
# get the latest release
VERSION=$(curl -s "https://api.github.com/repos/google/go-containerregistry/releases/latest" | jq -r '.tag_name')
ARCH=Darwin_arm64 # Linux_amd64

# download binary package and provenance file
curl -sL "https://github.com/google/go-containerregistry/releases/download/$VERSION/go-containerregistry_$ARCH.tar.gz" > go-containerregistry.tar.gz
curl -sL https://github.com/google/go-containerregistry/releases/download/$VERSION/multiple.intoto.jsonl > provenance.intoto.jsonl

# verify SLSA provenance
# note: go-containerregistry still publishes slsa-github-generator provenance,
# so this verification uses the slsa-verifier rather than the GitHub CLI
slsa-verifier verify-artifact \
    --provenance-path provenance.intoto.jsonl \
    --source-uri github.com/google/go-containerregistry \
    --source-tag $VERSION \
    go-containerregistry.tar.gz

Verifying artifact go-containerregistry.tar.gz: PASSED
PASSED: Verified SLSA provenance

# unpack crane in the $PATH
tar -zxvf go-containerregistry.tar.gz crane
chmod +x crane
sudo mv crane /usr/local/bin/crane
```

## jq

[jq](https://github.com/jqlang/jq) is a lightweight and flexible command-line JSON processor. We use it to inspect the provenance files. You can install it via Homebrew or see the [installation instructions](https://jqlang.github.io/jq/download/).

```bash
brew install jq
```
