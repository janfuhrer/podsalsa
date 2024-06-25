# GUAC

## Overview

[GUAC](https://github.com/guacsec/guac) stands for "Graph for Understanding Artifact Composition" and is a tool to analyze and visualize software dependencies. GUAC ingest software security metadata, such as SBOMs, and maps the relationships between software. The [GUAC Visualizer](https://docs.guac.sh/guac-visualizer/) can use to explore the various nodes and relationships. Since March 2024, GUAC is an [OpenSSF Incubator project](https://openssf.org/blog/2024/03/07/guac-joins-openssf-as-incubating-project/).

GUAC further implements [deps.dev](https://deps.dev) for source location, [OpenSSF Scorecards](https://securityscorecards.dev/) results and vulnerability data from [OSV.dev](https://osv.dev/) to combine all available data in one place.

GUAC supports [CycloneDX](https://cyclonedx.org/) and [SPDX](https://spdx.dev/) SBOM formats.

The `guacone` CLI is used to interact with the GUAC server (load SBOMs, mark packages as vulnerable, etc.).

For more information, see the [GUAC Docs](https://docs.guac.sh/).

## Install GUAC locally

See the [installation guide](./install-guac-locally.md) to install GUAC locally.

## Import SBOMs

First, we need to download the SBOMs of a project and import them into GUAC. The following example shows how to download the SBOMs of the `janfuhrer/podsalsa` project and import them into GUAC.

```bash
mkdir sboms
cd sboms

# get the latest release version
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')

# download all go archive sboms of this release
for ARTIFACT in $(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.assets[] | select(.name | endswith(".sbom.json")) | .name'); do curl -L -O -s https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/$ARTIFACT; done

# download sbom of container image
IMAGE=ghcr.io/janfuhrer/podsalsa:$VERSION
IMAGE="${IMAGE}@"$(crane digest "${IMAGE}")

COSIGN_REPOSITORY=ghcr.io/janfuhrer/sbom cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/janfuhrer/podsalsa/.github/workflows/release.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?$' \
  $IMAGE | jq -r '.payload' | base64 -d | jq -r '.predicate' > podsalsa-$VERSION.sbom
```

Import all SBOMs to guac:

```bash
guacone collect files ./
```

Inspect the imported SBOMs:

```bash
guacone query known package "pkg:golang/github.com/janfuhrer/podsalsa@$VERSION"
```

![guac-search-package](../../assets/guac/guac-search-package.png)

## Mark a package as vulnerable

Vulnerabilities are scanned against the [OSV](https://osv.dev/) database. To mark a package manually as vulnerable (e.g. in case of a zero day), use the following command:

```bash
# mark a package as vulnerable
guacone certify package -n "Zero Day" "pkg:golang/go.uber.org/multierr"
```

We now can query the affected packages:

```bash
guacone query bad
# select the created "Zero Day" vulnerability
```

This returns a "Visualizer url" which can be opened in a browser to see the affected packages in the `guac-visualizer` running on `localhost:8080`.

![guac-visualizer](../../assets/guac/guac-visualizer.png)

More information can be found in the [GUAC Docs](https://docs.guac.sh/).
