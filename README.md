# PodSalsa

[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/janfuhrer/podsalsa/badge)](https://securityscorecards.dev/viewer/?uri=github.com/janfuhrer/podsalsa)
[![release](https://img.shields.io/github/v/release/janfuhrer/podsalsa)](https://github.com/janfuhrer/podsalsa/releases)
[![license](https://img.shields.io/github/license/janfuhrer/podsalsa)](https://github.com/janfuhrer/podsalsa/blob/main/LICENSE)
[![go-version](https://img.shields.io/github/go-mod/go-version/janfuhrer/podsalsa)](https://github.com/janfuhrer/podsalsa/blob/main/go.mod)

<p align="center">
    <img src="./assets/podsalsa-logo.png" alt="PodSalsa" width="400">
</p>

---

PodSalsa is a simple web application that displays only information about the release version of the application, the Git commit and the build date.
The goal of this project is to provide a simple example of a Go application with workflows for building and releasing the application in a secure way.

More documentation will follow soon.

## Work in Progress 🏗️

- [ ] Implement the release workflow for sbom, docker images, code scanning, and signing
- [ ] Document the release workflows
- [ ] Document Security Policy (Verifying the release artifacts)
- [ ] Improve the application (more configuration option, better UI, scaling use-case)

## Documentation

- [PodSalsa Github Workflows](./.github/workflows/README.md)
- [GitHub Actions Best Practises](./docs/best-practises.md)
