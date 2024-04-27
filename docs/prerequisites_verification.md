# Prerequisites verification

## SLSA-Verifier

To verify the SLSA provenance, you need the [slsa-verifier](https://github.com/slsa-framework/slsa-verifier) binary. You can install it via Homebrew or download it from GitHub.

Download with Hombrew:

```bash
brew install slsa-verifier
```

Download binary from GitHub and verify checksum:

```bash
# get the latest release
export VERSION=$(curl -s "https://api.github.com/repos/slsa-framework/slsa-verifier/releases/latest" | jq -r '.tag_name')
export ARCH=darwin-arm64 # linux-amd64

# download binary and shasum file
curl -L -O https://github.com/slsa-framework/slsa-verifier/releases/download/$VERSION/slsa-verifier-$ARCH
curl -L -O https://raw.githubusercontent.com/slsa-framework/slsa-verifier/main/SHA256SUM.md

# simplify shasum file since it has all hashes for all versions in it
sed -n "/### \[${VERSION}\]/,/^### /p" SHA256SUM.md | grep -vE '^###|^$' > sha256sum_filtered

# shasum check on macOS
shasum -a 256 -c --ignore-missing --strict sha256sum_filtered

# shasum check on linux
sha256sum -c --strict --ignore-missing sha256sum_filtered

# make binary executable and move it to a location in your $PATH
chmod +x slsa-verifier-$ARCH
sudo mv slsa-verifier-$ARCH /usr/local/bin/slsa-verifier
```

## Cosign

As an alternative to the SLSA-Verifier, you can use the [Cosign](https://github.com/sigstore/cosign) CLI to verify the docker images and the checksum file.

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
