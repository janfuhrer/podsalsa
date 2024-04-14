# PodSalsa

[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/janfuhrer/podsalsa/badge)](https://securityscorecards.dev/viewer/?uri=github.com/janfuhrer/podsalsa)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8791/badge)](https://www.bestpractices.dev/projects/8791)
[![release](https://img.shields.io/github/v/release/janfuhrer/podsalsa)](https://github.com/janfuhrer/podsalsa/releases)
[![license](https://img.shields.io/github/license/janfuhrer/podsalsa)](https://github.com/janfuhrer/podsalsa/blob/main/LICENSE)
[![go-version](https://img.shields.io/github/go-mod/go-version/janfuhrer/podsalsa)](https://github.com/janfuhrer/podsalsa/blob/main/go.mod)

<p align="center">
    <img src="./assets/podsalsa-logo.png" alt="PodSalsa" width="400">
</p>

---

PodSalsa is a simple web application that only displays information about the release version of the application, the Git commit and the build date.
The goal of this project is to provide a simple example of a Go application on GitHub with GitHub Actions for building and releasing the application in a secure way. The focus is on providing a summary/documentation of GitHub Actions best practices, code scanning workflows, vulnerability scanning, and techniques for releasing secure software to improve the security of the software supply chain.

## Work in Progress 🏗️

- [ ] Implement the release workflow for sbom, docker images, code scanning, and signing
- [ ] Document the release workflows
- [ ] Document Security Policy (Verifying the release artifacts)
- [ ] Improve the application (more configuration option, better UI, scaling use-case)

## Documentation

All the used workflows and security best practises are documented in the following files:

- [PodSalsa Github Workflows](./.github/workflows/README.md)
- [GitHub Actions Best Practises](./docs/best-practises.md)
