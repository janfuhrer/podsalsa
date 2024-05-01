# Kubernetes enforcement with Kyverno

In this example we will use [Kyverno](https://kyverno.io/) to enforce SLSA verification in a Kubernetes cluster. This example uses a local kind cluster to demonstrate the enforcement.

## Install local kind cluster

Install [kind](https://kind.sigs.k8s.io/) and create a local cluster.

```bash
# install kind
brew install kind

# create local cluster
kind create cluster
```

## Install Kyverno

We are using [Helm](https://helm.sh/) to install Kyverno in the cluster. The values of the Helmchart are available [here](https://github.com/kyverno/kyverno/tree/main/charts/kyverno). For this example we are using the default values.

```bash
# install kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# verify installation
kubectl get pods -n kyverno
```

## Deploy the application

First, we deploy the [Kyverno policy](./kyverno/clusterpolicy-slsa.yaml) which enforces the SLSA verification for the podsalsa application.

```bash
# install kyverno policies
kubectl apply -f kyverno/clusterpolicy-slsa.yaml
```

Next, we deploy the podsalsa application with a valid SLSA verification.

```bash
kubectl apply -f deployment.yaml

deployment.apps/podsalsa created
```

Now, we deploy the podsalsa application with an invalid SLSA verification (version `v0.1.0` has no provenance).

```bash
kubectl apply -f deployment-fail.yaml

Error from server: error when creating "deployment-fail.yaml": admission webhook "mutate.kyverno.svc-fail" denied the request: 

resource Deployment/default/podsalsa-fail was blocked due to the following policies 

verify-slsa-provenance-keyless:
  autogen-check-slsa-keyless: 'image attestations verification failed, verifiedCount:
    0, requiredCount: 1, error: no matching attestations: '
```
