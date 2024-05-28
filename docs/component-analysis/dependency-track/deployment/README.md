# Deploy sbom-operator

## Create API token in Dependency-Track

Create a new API key for the `Automation` team in the `Configuration/Access Management/Teams` section. Following permissions are required:

- `BOM_UPLOAD`
- `PORTFOLIO_MANAGEMENT`
- `PROJECT_CREATION_UPLOAD`
- `VIEW_PORTFOLIO`
- `VIEW_VULNERABILITY`
- `VULNERABILITY_ANALYSIS`
- `VULNERABILITY_MANAGEMENT`

## Deploy sbom-operator

Update the `secret.yaml` with the API token from Dependency-Track and the `values.yaml` with the correct URL of Dependency-Track and the cluster name.

Install the sbom-operator with the following commands:

```bash
helm repo add ckotzbauer https://ckotzbauer.github.io/helm-charts
helm repo update

kubectl apply -f secret.yaml

helm install sbom-operator ckotzbauer/sbom-operator -n sbom-operator --create-namespace -f values.yaml
```
