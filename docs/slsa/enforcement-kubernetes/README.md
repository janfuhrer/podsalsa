# Kubernetes enforcement with Kyverno

In this example we will use [Kyverno](https://kyverno.io/) to enforce SLSA verification in a Kubernetes cluster. This example uses a local kind cluster to demonstrate the enforcement.

> [!IMPORTANT]
> The [policy](./kyverno/clusterpolicy-slsa.yaml) describes the **SLSA v1** provenance that GitHub Artifact Attestations produce, and pins the trusted builder `build-image.yml`. It therefore only matches images from **v0.10.0 onwards**.
>
> Releases up to v0.9.x carry SLSA v0.2 provenance signed by the `slsa-github-generator` and will be rejected by this policy. The image in [deployment.yaml](./deployment.yaml) still points at such a release, so it needs to be updated to a v0.10.0+ digest before the "valid deployment" step below succeeds. Verifying those older images requires the v0.2 policy shown in [Legacy verification](../../../archive/verification-legacy.md).
>
> Kyverno must also be able to read attestations stored as OCI 1.1 referrers, which requires `verifyImages[].type: SigstoreBundle` and therefore a current Kyverno release. With the default `type: Cosign` the attestation is not found at all.

> [!NOTE]
> Kyverno is not GitHub's own recommendation for enforcing artifact attestations — that is the [Sigstore Policy Controller](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/enforce-artifact-attestations), for which GitHub publishes a ready-made `ClusterImagePolicy` and trust root. An example policy-controller configuration is kept in [archive/policy-controller](../../../archive/policy-controller/). We use Kyverno here because it is not limited to SLSA verification, but either tool works.
>
> One Kyverno detail worth knowing when writing conditions: the variable context is rooted at the **predicate**, not at the in-toto statement. Write `{{ buildDefinition.buildType }}`, not `{{ predicate.buildDefinition.buildType }}`.

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
curl -sSL https://raw.githubusercontent.com/janfuhrer/podsalsa/main/docs/slsa/enforcement-kubernetes/kyverno/clusterpolicy-slsa.yaml | kubectl apply -f -
```

Next, we deploy the podsalsa application with a valid SLSA verification.

```bash
curl -sSL https://raw.githubusercontent.com/janfuhrer/podsalsa/main/docs/slsa/enforcement-kubernetes/deployment.yaml | kubectl apply -f -

deployment.apps/podsalsa created
```

Now, we deploy the podsalsa application with an invalid SLSA verification (version `v0.1.0` has no provenance).

```bash
curl -sSL https://raw.githubusercontent.com/janfuhrer/podsalsa/main/docs/slsa/enforcement-kubernetes/deployment-fail.yaml | kubectl apply -f -

Error from server: error when creating "STDIN": admission webhook "mutate.kyverno.svc-fail" denied the request: 

resource Deployment/default/podsalsa was blocked due to the following policies 

verify-slsa-provenance-keyless:
  autogen-check-slsa-keyless: 'image attestations verification failed, verifiedCount:
    0, requiredCount: 1, error: no matching attestations: '
```

## Cleanup

Delete the local kind cluster:

```bash
kind delete cluster
```
