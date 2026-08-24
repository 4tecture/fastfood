# Kubernetes admission policies

`require-image-digests.yaml` is a native Kubernetes `ValidatingAdmissionPolicy`
that rejects Pods using mutable image tags. It only affects namespaces carrying
the opt-in label, so it can be introduced safely before enforcement:

```bash
kubectl apply -f infrastructure/policies/require-image-digests.yaml
kubectl label namespace production fastfood.dev/require-image-digests=true
```

Deploy charts with `image.digest` populated from the CI `image-metadata`
artifact before enabling the label. Signature verification should be enforced
by the cluster's admission controller and the public key used by
`pipelines/security/step-signandverifyimage.yml`.

The target cluster must serve `admissionregistration.k8s.io/v1` for both
`ValidatingAdmissionPolicy` resources. Pin the Dapr control-plane and injected
sidecar images by digest before enabling this policy in a Dapr namespace.
