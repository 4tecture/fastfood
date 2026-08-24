# Hands-on lab: secure, reusable Azure Pipelines templates

## Goal

Build one service with the repository's reusable templates, publish an
immutable container image plus provenance metadata, package its Helm chart,
and deploy it atomically to Kubernetes.

The current implementation intentionally demonstrates these controls:

- BuildKit secrets for authenticated NuGet restores; credentials never become
  image layers or build arguments.
- committed NuGet lock files and `--locked-mode` restores;
- unit-test and Cobertura results exported directly from a scratch BuildKit target;
- a unique build-number image tag, with no mutable `latest` publication;
- BuildKit SBOM and SLSA provenance attestations;
- a published `image-metadata` artifact containing the registry digest;
- blocking dependency, vulnerability, license, and IaC scans;
- optional Cosign signing and verification of the immutable digest;
- atomic Helm deployment with readiness checks and rollback on failure.

## 1. Inspect the image-build step

Open `pipelines/build/step-buildandpublishdockerimage.yml`. Its public inputs
are the Dockerfile, build context, registry service connection, repository,
build identity, optional NuGet feeds, and optional artifact-producing Docker
targets.

Each service Dockerfile publishes its runtime payload once, runs tests in a
dependent stage, exposes evidence through `test-results`, and makes `final`
inherit the tested graph. The release build therefore reuses the tested payload
instead of invoking `dotnet publish` a second time.

A service job passes one or more images through the `dockerImages` collection:

```yaml
- template: build/job-buildcontainerizedservice.yml
  parameters:
    displayName: Build Order Service
    chartPath: $(helmChartSourcePath)
    artifactName: $(pipelineArtifactName)
    azureContainerRegistryServiceConnection: $(azureContainerRegistryServiceConnection)
    netCoreAspNetVersion: $(netCoreAspNetVersion)
    netCoreSdkVersion: $(netCoreSdkVersion)
    helmVersion: $(helmVersion)
    artifactStagingDirectory: $(Build.ArtifactStagingDirectory)
    buildId: $(Build.BuildId)
    buildNumber: $(Build.BuildNumber)
    servicePaths:
      - $(componentPath)
    serviceTagPrefix: $(versionTagPrefix)
    installMonotag: false
    updateBuildNumber: true
    nugetFeeds: []
    dockerImages:
      - dockerRepositoryName: $(dockerRepositoryName)
        dockerFile: $(dockerFilePath)
        buildContext: $(Build.SourcesDirectory)/src
        dockerArguments: >-
          --build-arg IMAGE_NET_ASPNET_VERSION=$(netCoreAspNetVersion)
          --build-arg IMAGE_NET_SDK_VERSION=$(netCoreSdkVersion)
        publishArtifacts:
          - dockerfileTarget: test-results
            artifactName: testresults
            publishType: testResults
```

Order Service adds a second item for the actor image. This is the important
microservice lesson: every deployed workload must be built, scanned, and
promoted by the pipeline—not just the HTTP entry point.

## 2. Verify the supply-chain output

Run the CI pipeline and inspect its artifacts:

1. `testresults` contains `.trx` files and timestamped `*.coverage.cobertura.*.xml` reports.
2. `image-metadata/<repository>.json` contains `containerimage.digest` and
   BuildKit attestation metadata.
3. The Helm artifact contains the packaged chart and environment values.
4. The registry has the build-number tag, but no newly published `latest` tag.

For a production pipeline, download the Cosign key pair from Azure DevOps
Secure Files and call the signing template after registry authentication:

```yaml
- template: security/step-signandverifyimage.yml
  parameters:
    imageReference: $(azureContainerRegistry)/$(dockerRepositoryName):$(Build.BuildNumber)
    privateKeySecureFile: fastfood-cosign.key
    publicKeySecureFile: fastfood-cosign.pub
```

Store `cosignPassword` as a secret variable. Production clusters should verify
the same public key at admission time. Keyless signing with workload identity
is preferable where the Azure DevOps organization and transparency-log policy
are configured for it.

## 3. Inspect the security job

Open `pipelines/security/job-securityscan.yml` and identify:

- CodeQL initialization/build/analyze;
- dependency scanning after a locked restore;
- Trivy filesystem, image, license, and Helm/Kubernetes configuration scans;
- Trivy v2's explicit `failOnSeverityThreshold: HIGH` policy;
- `ignoreUnfixed: true`, which prevents vulnerabilities without an available
  fix from blocking a training pipeline;
- blocking scanner/runtime errors and the absence of `continueOnError`
  bypasses.

The task evaluates every configured severity for vulnerabilities with an
available fix, but only High and Critical findings fail the default CI policy.
Fixable Medium and Low findings remain visible in the generated reports. This
keeps the demo dependable while preserving a meaningful enterprise security
gate; use a separate non-gating inventory scan when complete unfixed-
vulnerability visibility is required.

Exercise: introduce a `:latest` image in a chart values file and confirm the
configuration scan or review gate catches it. Revert it before continuing.

## 4. Deploy with the job template

The deployment job downloads the chart artifact and invokes
`deploy/step-deployhelmchart.yml`:

```yaml
- template: deploy/job-deployservicetok8s.yml
  parameters:
    environment: fastfood-staging
    namespace: staging
    valuesFile: $(helmChartArtifactValuesFileDownloadPath)
    artifactName: $(pipelineArtifactName)
    chartPackage: $(helmChartArtifactDownloadPath)
    kubernetesDeploymentServiceConnection: $(kubernetesDeploymentServiceConnection)
    updateBuildNumber: true
    tokenizerSecrets: []
    pool:
      vmImage: ubuntu-24.04
```

The Helm step selects the equivalent rollback flag for Helm 3 or 4 and combines
it with `--wait`, `--wait-for-jobs`, `--cleanup-on-fail`, a bounded timeout, and
history retention. A failed readiness probe or migration Job therefore rolls
the release back instead of leaving a half-deployed workload.

## 5. Promote by digest

Before enabling production admission enforcement:

1. Read the digest from the CI `image-metadata` artifact.
2. Set the chart's `image.digest` value and retain the tag only as human-readable
   context.
3. Verify the Cosign signature.
4. Apply `infrastructure/policies/require-image-digests.yaml`.
5. Label the production namespace with
   `fastfood.dev/require-image-digests=true`.

This separates *building* from *promotion*: staging and production consume the
same verified image bytes even when tags move or registries are replicated.

## Completion checks

- CI fails when tests, locked restore, scanner/runtime errors, or fixable High
  or Critical security findings violate the policy.
- The final image runs as non-root and exposes the live/ready probes.
- The digest recorded by CI matches the digest deployed by Helm.
- Deployment rollback is demonstrated by temporarily using an invalid
  readiness path.
- No registry password, NuGet credential, Kubernetes token, database password,
  or signing private key is committed or printed in logs.
