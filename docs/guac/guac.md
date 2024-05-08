# GUAC

## Overview

tbd

## Import SBOMs

```bash
mkdir sboms
cd sboms

# import podsalsa sboms for the latest release
export VERSION=$(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.tag_name')
for ARTIFACT in $(curl -s "https://api.github.com/repos/janfuhrer/podsalsa/releases/latest" | jq -r '.assets[] | select(.name | endswith(".sbom")) | .name'); do curl -L -O -s https://github.com/janfuhrer/podsalsa/releases/download/$VERSION/$ARTIFACT; done

# download all available sboms of janfuhrer/podsalsa/sbom
for SBOM_TAG in $(crane ls ghcr.io/janfuhrer/sbom); do crane export ghcr.io/janfuhrer/sbom:$SBOM_TAG ./$SBOM_TAG; done
```

Import all SBOMs to guac:

```bash
guacone collect files
```

## Mark a package as vulnerable

```bash
# mark a package as vulnerable
guacone certify package -n "Zero Day" "pkg:golang/go.uber.org/multierr"

# see affected packages
guacone query bad
```