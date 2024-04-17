# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change. 

Please note we have a [code of conduct](./CODE_OF_CONDUCT.md), please follow it in all your interactions with the project.

## How to Contribute

With these steps you can make a contribution:

  1. Fork this repository, develop your changes on that fork
  2. Commit changes
  3. Submit a [pull request](#pull-requests) from your fork to this project.

Before starting, go through the requirements below.  

### Commits

Please have meaningful commit messages. We recommend the creation of commit messages according to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

### Commit Signature Verification

Each commit's signature must be verified.

  * [About commit signature verification](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/about-commit-signature-verification)

## Pull Requests

All submissions, including submissions by project members, require review. We use GitHub pull requests for this purpose. Consult [GitHub Help](https://help.github.com/articles/about-pull-requests/) for more information on using pull requests. See the above stated requirements for PR on this project.

## Code convention

## Pre-Commit

Please install [pre-commit](https://pre-commit.com/) to enforce some checks before commiting
After clone you need to install the hook script manually:

```bash
pre-commit install
```

## golint

We check the code with [golangci-lint](https://github.com/golangci/golangci-lint) to enforce some code conventions. You can run it with:

```bash
golangci-lint run
```
