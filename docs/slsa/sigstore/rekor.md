# Rekor

It is possible to communicate with the Rekor transparency log using the `rekor-cli` tool. The following example shows how to use the `rekor-cli` to search for an image in the transparency log and get the corresponding signatures and certificates.

## Pre-requisites

You can download the `rekor-cli` from the [Rekor releases page](https://github.com/sigstore/rekor/releases) or use Homebrew:

```bash
brew install rekor-cli
```

## Usage

Rekor entries are found by the digest of the signed artifact, so all you need is the image digest:

```bash
VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
IMAGE=ghcr.io/janfuhrer/podsalsa:$VERSION

# get the image digest (without the "sha256:" prefix)
SHASUM=$(crane digest $IMAGE | cut -d: -f2)

# get rekor uuids
rekor-cli search --sha $SHASUM
```

This returns a list of UUIDs — one per signature stored for the image:

```
Found matching entries (listed by UUID):
108e9186e8c5677aaeacf8c41f62f19be15cf3a64cfba3686cb719dc0d0bcb9a0ece7331c794b14c
108e9186e8c5677ad9622262256511206f440c13ad4786c56e7b207318dd648ade5904139cd80788
108e9186e8c5677a7673956f89410b01197a71a81436b5eee8dde3a532ccff56fb5d7813ba3ab6fc
```

For a container image there are three: the image signature, the CycloneDX SBOM attestation, and the SLSA build provenance. To see which is which, read the attestations out of the registry and look at their predicate types:

```bash
cosign download attestation $IMAGE | \
  jq -r '.dsseEnvelope.payload' | base64 -d | jq -r '.predicateType'
```

```
https://cyclonedx.org/bom
https://sigstore.dev/cosign/sign/v1
https://slsa.dev/provenance/v1
```

> [!NOTE]
> These are [Sigstore bundles](https://github.com/sigstore/protobuf-specs), so the statement lives under `.dsseEnvelope.payload`. A plain `.payload` returns `null` and the subsequent `base64 -d | jq` fails with `Invalid numeric literal`.

## Inspecting an entry

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

Sigstore uses custom OIDs to store information about the certificate, defined in the [Fulcio docs](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md). The most useful one here is `Build Signer URI` (OID `1.3.6.1.4.1.57264.1.9`), which names the workflow that requested the signature:

```bash
rekor-cli get --format json --uuid ${UUID} | \
    jq -r '.Body.DSSEObj.signatures[].verifier' | base64 -d | \
    openssl x509 -text -noout | grep -A1 '1.3.6.1.4.1.57264.1.9' | tail -1
```

```
https://github.com/janfuhrer/podsalsa/.github/workflows/build-image.yml@refs/tags/v0.10.0
```

Note that this names the **trusted builder** that ran the build — the reusable workflow — and not the `release.yml` that called it. That distinction is what [`gh attestation verify` pins](../../../SECURITY.md#verify-container-images) when it checks the signer identity.
