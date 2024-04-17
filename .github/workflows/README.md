# PodSalsa Github Workflows

## Overview

Following workflows are implemented in the repository.
[SARIF](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/sarif-support-for-code-scanning) is used to store the results for an analysis of code scanning tools in the Security tab of the repository.

| Workflow                                           | Jobs                | Trigger                                | SARIF upload | Description                                                                                      |
| :------------------------------------------------- | :------------------ | :------------------------------------- | :----------- | ------------------------------------------------------------------------------------------------ |
| [codeql.yaml](./codeql.yaml)                       | `analyze`           | push/pr to `main`, cron: `00 13 * * 1` | yes          | Semantic code analysis                                                                           |
| [dependency-review.yaml](./dependency-review.yaml) | `dependency-review` | pr to `main`                           | -            | Check pull request for vulnerabilities in dependencies or invalid licenses are being introduced. |
| [fossa.yaml](./fossa.yaml)                         | `analyze`           | push/pr on `*`                         | -            | FOSSA analysis                                                                                   |
| [golangci-lint.yaml](./golangci-lint.yaml)         | `lint`              | push/pr on `*`                         | -            | Lint Go Code                                                                                     |
| [gosec.yaml](./gosec.yaml)                         | `analyze`           | push/pr on `*`                         | -            | Inspects source code for security problems in Go code                                            |
| [osv-scan.yaml](./osv-scan.yaml)                   | `analyze`           | push/pr to `main`, cron: `30 13 * * 1` | yes          | Scanning for vulnerabilites in dependencies                                                      |
| [release.yaml](./release.yaml)                     | `args`              | push tag `v*`                          | -            | Get variables for go build                                                                       |
| [release.yaml](./release.yaml)                     | `go-release`        | push tag `v*`                          | -            | Release the go-binaries for multiple platforms                                                   |
| [scorecard.yaml](./scorecard.yaml)                 | `analyze`           | push to `main`, cron: `00 14 * * 1`    | yes          | Create OpenSSF analysis and create project score                                                 |

## CodeQL

TODO: describe workflow

## Dependency Review

TODO: describe workflow

## FOSSA

TODO: Check implementation of the FOSSA workflow (https://github.com/fossa-contrib/fossa-action)

## GolangCI-Lint

TODO: describe workflow

## Gosec

TODO: describe workflow (https://github.com/securego/gosec)

## OSV-Scan

[OSV-Scanner](https://google.github.io/osv-scanner/) to find existing vulnerabilites affecting dependencies in the project.

## Release

TODO: describe workflow

## Scorecards

TODO: describe workflow
