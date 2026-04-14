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
go 1.26.2
```

### 3. Update hardcoded GOTOOLCHAIN in workflows

Two workflows hardcode the toolchain version and must be updated manually:

- [.github/workflows/codeql.yml](.github/workflows/codeql.yml) — `GOTOOLCHAIN: "go1.26.2"`
- [.github/workflows/gosec.yml](.github/workflows/gosec.yml) — `GOTOOLCHAIN: "go1.26.2"`

The following workflows use `go-version-file: 'go.mod'` and pick up the version automatically — no changes needed:

- [.github/workflows/golangci-lint.yml](.github/workflows/golangci-lint.yml)
- [.github/workflows/release.yml](.github/workflows/release.yml)

### 4. Update `-compat` flag in Makefile (major/minor version bumps only)

[Makefile](Makefile) line 15 has a hardcoded `-compat` flag:

```makefile
go mod tidy -compat=1.26
```

Update this when the `major.minor` version changes (not needed for patch-only bumps).

### 5. Update prek hooks

[prek.toml](prek.toml) pins the `rev` of each hook repository. Update all revisions to their latest tags:

```bash
prek auto-update
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

### 7. Update ko version

[Makefile](Makefile) hardcodes the ko version:

```makefile
KO_VERSION  = v0.18.1
```

Check the latest release and update the version:

```bash
gh release view --repo google/ko --json tagName -q '.tagName'
```

Then update `KO_VERSION` in [Makefile](Makefile) accordingly.
