# PodSalsa Github Workflows

## Release

The release workflow is triggered by a new Git tag and performs the following steps:

- Create the go binaries for multiple platforms
- TODO: Generates a Software Bill of Materials (SBOM)
- TODO: Create multi-arch docker images
- TODO: Signs the sbom, the binaries checksum and the container images with Cosign and GitHub OIDC
- TODO: Upload the sbom, binaires, checksums to GitHub Releases
- TODO: Pushes the container images to GitHub Container Registry and DockerHub

| Workflow                           | Jobs         | Runners       | Description                                                  |
| :--------------------------------- | :----------- | :------------ | :----------------------------------------------------------- |
| [codecov.yaml](./codecov.yaml)     | `analyze`    | Github Ubuntu | Code analysis of Codecov                                     |
| [codeql.yaml](./codeql.yaml)       | `analyze`    | Github Ubuntu | Code analysis of CodeQL                                      |
| [release.yaml](./release.yaml)     | `args`       | Github Ubuntu | Get variables for go build                                   |
| [release.yaml](./release.yaml)     | `go-release` | Github Ubuntu | Release the go-binaries for multiple platforms               |
| [scorecard.yaml](./scorecard.yaml) | `analysis`   | Github Ubuntu | Create OpenSSF analysis, upload SARIF result to security tab |

## CodeQL

TODO: describe workflow

## Scorecards

TODO: describe workflow

## Gosec

TODO: Check implementation of the Gosec workflow (https://github.com/securego/gosec)

## Codecov

TODO: Check implementation of the Codecov workflow (https://github.com/codecov/codecov-action)

## Linting

TODO: Implement a workflow for go linting

## FOSSA

TODO: Check implementation of the FOSSA workflow (https://github.com/fossa-contrib/fossa-action)
