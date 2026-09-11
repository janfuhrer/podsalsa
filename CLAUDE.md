# CLAUDE.md

## Updating Go version and dependencies

When updating to a new Go version or upgrading dependencies, touch all of the following locations:

### 1. Update Go modules

```bash
# Update all dependencies to latest versions
make go-update   # runs: go get -u ./... && go mod tidy -compat=<major.minor>
```

Or manually:

```bash
go get -u ./...
go mod tidy
```

### 2. Update the Go version directive in go.mod

Edit [go.mod](go.mod) and bump the `go` directive:

```
go 1.27.1
```

### 3. Update hardcoded GOTOOLCHAIN in workflows

Two workflows hardcode the toolchain version and must be updated manually:

- [.github/workflows/codeql.yml](.github/workflows/codeql.yml) — `GOTOOLCHAIN: "go1.27.1"`
- [.github/workflows/gosec.yml](.github/workflows/gosec.yml) — `GOTOOLCHAIN: "go1.27.1"`

The following workflows use `go-version-file: 'go.mod'` and pick up the version automatically — no changes needed:

- [.github/workflows/golangci-lint.yml](.github/workflows/golangci-lint.yml)
- [.github/workflows/release.yml](.github/workflows/release.yml)

### 4. Update `-compat` flag in Makefile (major/minor version bumps only)

[Makefile](Makefile) line 15 has a hardcoded `-compat` flag:

```makefile
go mod tidy -compat=1.27
```

Update this when the `major.minor` version changes (not needed for patch-only bumps).

### 5. Update prek hooks

[prek.toml](prek.toml) pins the `rev` of each hook repository. Update all revisions to their latest tags:

```bash
prek update
```

This updates the `rev` fields for all four repos in [prek.toml](prek.toml):
- `pre-commit/pre-commit-hooks`
- `gitleaks/gitleaks`
- `tekwizely/pre-commit-golang`
- `golangci/golangci-lint`

### 6. Verify

```bash
go build ./...
go test ./...
```

### 7. Update pinned tool versions

[Makefile](Makefile) hardcodes the version of every Go tool it installs:

```makefile
KO_VERSION              = v0.19.1
CYCLONEDX_GOMOD_VERSION = v1.12.0
CUE_VERSION             = v0.17.1
```

Check the latest releases and update the versions:

```bash
gh release view --repo google/ko --json tagName -q '.tagName'
gh release view --repo CycloneDX/cyclonedx-gomod --json tagName -q '.tagName'
gh release view --repo cue-lang/cue --json tagName -q '.tagName'
```

### 8. Verify the release pipeline still lints

The release workflows are security-relevant, so lint them after any change:

```bash
actionlint
```

## Release provenance (SLSA Build L3)

The release pipeline is split into a caller and two trusted builders. Do not collapse
them back into a single workflow — the separation is what makes the provenance
SLSA Build Level 3.

- [.github/workflows/release.yml](.github/workflows/release.yml) only triggers the builds and passes no build inputs.
- [.github/workflows/build-binaries.yml](.github/workflows/build-binaries.yml) and [.github/workflows/build-image.yml](.github/workflows/build-image.yml) run the builds and sign their own provenance.

Consequences to keep in mind when editing:

- The signing identity in every keyless signature is the **trusted builder**, not `release.yml`.
  Renaming either build workflow changes that identity and therefore invalidates the
  `--certificate-identity-regexp` values in [SECURITY.md](SECURITY.md) and
  [.github/workflows/release-verification.yml](.github/workflows/release-verification.yml), the
  `--signer-workflow` values, the `builder.id` regex in [policy.cue](policy.cue), and the keyless
  subject in [the Kyverno policy](docs/slsa/enforcement-kubernetes/kyverno/clusterpolicy-slsa.yaml).
- [policy.cue](policy.cue) describes the SLSA **v1** predicate emitted by
  `actions/attest-build-provenance`. Verify changes to it against a real statement with
  `cue vet policy.cue statement.json`.
