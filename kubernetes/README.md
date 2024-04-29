# Kubernetes

## Test with kind

```bash
# create kind cluster
kind create cluster

# install kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# install kyverno policies
kubectl apply -f kyverno/clusterpolicy.yaml

kubectl apply -f deployment.yaml
```
