# Rekor

It is possible to communicate with the Rekor transparency log using the `rekor-cli` tool. The following example shows how to use the `rekor-cli` to search for an image in the transparency log and get the corresponding signatures and certificates.

## Pre-requisites

You can download the `rekor-cli` from the [Rekor releases page](https://github.com/sigstore/rekor/releases) or use Homebrew:

```bash
brew install rekor-cli
```

## Usage

```bash
VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
IMAGE=ghcr.io/janfuhrer/podsalsa:$VERSION

# inspect the SLSA provenance attestation and get the image shasum
# note: SLSA provenance is stored in the old bundle format in the image repository (v0.9.0+)
#       for v0.7.x and earlier, add: COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures
SHASUM=$(cosign download attestation $IMAGE | jq -r '.payload' | base64 -d | jq -r '.subject[].digest.sha256')

# get rekor uuids
rekor-cli search --sha $SHASUM
```

This will return a list of UUIDs. You can then use the UUID to get the log entry from the transparency log and extract the certificate. Sigstore uses custom OIDs to store information about the certificate. The OIDs are defined in the [Fulcio docs](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md).

For a container image there will be two entries, one for the image signature and one for the provenance. You can tell them apart by the `Build Signer URI` field (certificate OID `1.3.6.1.4.1.57264.1.9`), which contains the workflow that requested the signature. Both are signed from the trusted builder `build-image.yml`, so the field reads `.../.github/workflows/build-image.yml@refs/tags/<version>` for each — note that it names the reusable workflow that ran the build, not the `release.yml` that called it.

You can check the log entries either by looking at the entry in the transparency log https://search.sigstore.dev/ or by using the `rekor-cli`:

```bash
rekor-cli get --format json --uuid ${UUID} | jq
```

To retrieve the short-lived certificate from the Rekor log entry, you can use the following command:

```bash
rekor-cli get --format json --uuid ${UUID} | \
    jq -r '.Body.DSSEObj.signatures[].verifier' | \
    base64 -d | openssl x509 -text -noout
```
