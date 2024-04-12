# Best practices & security considerations

This document outlines the best practices for writing and maintaining Gitworkflows in GitHub Actions. For the full security hardening Guide refer to the [GitHub Actions Security Hardening Guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions).

## Using secrets

Always use secrets for sensitive data like API keys, passwords, and tokens. Never hardcode secrets in the workflow files. Secrets are encrypted and stored in GitHub, and they are never printed in the logs.

Documentation how to use secrets in GitHub Actions can be found [here](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions).

```yaml
jobs:
  test:
    name: use a secret
    runs-on: ubuntu-latest
    steps:
    - name: Use a secret
      env:
        MY_SECRET: ${{ secrets.MY_SECRET }}
      run: echo $MY_SECRET
```