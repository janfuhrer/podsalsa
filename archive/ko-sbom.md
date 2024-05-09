# Crane commands for ko SBOMs

> [!IMPORTANT]
> The SBOMs created by ko are not signed (at least for now). You should disable sbom generation in the `ko` build process and build the SBOM yourself and use the `cosign attest` command to sign and upload the SBOMs (see the [release workflow](../.github/workflows/release.yml) and [publish-image](../.github/actions/publish-image/action.yaml) actions).

## goreleaser.yml

To build the container images and sbom directly with the goreleaser, you can use the following configuration in the `goreleaser.yml` file:

```yaml
kos:
  - id: podsalsa
    build: podsalsa
    repository: ghcr.io/janfuhrer/podsalsa
    tags:
      - '{{.Tag}}'
      - '{{ if not .Prerelease }}latest{{ end }}'
    # use default base image
    base_image: cgr.dev/chainguard/static
    labels:
      org.opencontainers.image.created: '{{ .Date }}'
      org.opencontainers.image.authors: "janfuhrer@mailbox.org"
      org.opencontainers.image.url: "https://github.com/janfuhrer/podsalsa"
      org.opencontainers.image.documentation: "https://github.com/janfuhrer/podsalsa"
      org.opencontainers.image.source: "https://github.com/janfuhrer/podsalsa"
      org.opencontainers.image.version: '{{ .Tag }}'
      org.opencontainers.image.revision: '{{ .Commit }}'
      org.opencontainers.image.vendor: "janfuhrer"
      org.opencontainers.image.licenses: "Apache-2.0"
      org.opencontainers.image.title: "Podsalsa"
      org.opencontainers.image.description: "Sample application to demonstrate supply chain security."
      org.opencontainers.image.base.name: "cgr.dev/chainguard/static"
    # use the docker tag without anything additional
    bare: true
    preserve_import_paths: false
    sbom: cyclonedx # or spdx
    platforms:
      # possible values: all, linux/s390x, linux/arm64, linux/arm/v7, linux/ppc64le, linux/amd64
      - linux/arm64
      - linux/arm/v7
      - linux/amd64
    # set for reproducible builds
    creation_time: '{{ .CommitTimestamp }}'
    ko_data_creation_time: '{{.CommitTimestamp}}'
```
## Download SBOMs from the container registry

You can use `crane` to download and inspect the SBOMs as follows:

```bash
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

# get digest of a specific image tag
export SBOM_TAG=$(crane digest ghcr.io/janfuhrer/podsalsa:$VERSION | sed -E 's/sha256:([0-9a-f]+)/sha256-\1.sbom/')

# download SBOM
crane export ghcr.io/janfuhrer/sbom:$SBOM_TAG ./$SBOM_TAG

# inspect SBOM
less $SBOM_TAG
```

Download all available SBOMs:

```bash
for TAG in $(crane ls ghcr.io/janfuhrer/podsalsa); do crane export ghcr.io/janfuhrer/sbom:$SBOM_TAG ./$SBOM_TAG; done
```
