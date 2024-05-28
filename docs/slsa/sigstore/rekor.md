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

# inspect attestation and get shasum of the image in the attestation
SHASUM=$(COSIGN_REPOSITORY=ghcr.io/janfuhrer/signatures cosign download attestation $IMAGE | jq -r '.payload' | base64 -d | jq -r '.subject[].digest.sha256')

# get rekor uuids
rekor-cli search --sha $SHASUM
```

This will return a list of UUIDs. You can then use the UUID to get the log entry from the transparency log and extract the certificate. Sigstore uses custom OIDs to store information about the certificate. The OIDs are defined in the [Fulcio docs](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md).

For a container image there will be two entries, one for the image signature and one for the provenance file. You can tell them apart by the `Build Signer URI` field (certificate OID `1.3.6.1.4.1.57264.1.9`), which contains the name of the workflow that requested the signature. The workflow for the image signature is `release.yml` and for the provenance file signature is `generator_container_slsa3.yml`.

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
