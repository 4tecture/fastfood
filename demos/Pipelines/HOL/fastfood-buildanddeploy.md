# Hands-on lab: build and deploy one service with Azure Pipelines

## Outcome

Create CI and CD pipelines for Frontend Self Service POS using the repository's
production templates. CI builds and tests the image, produces SBOM/provenance
metadata, scans it, and packages Helm. CD promotes the same artifact through
staging and production with an isolated pull-request path.

## Prerequisites

- Azure DevOps service connections for ACR and Kubernetes;
- protected environments for staging and production;
- the repository variable templates under `pipelines/config`;
- a build agent with Docker Buildx, .NET 10, Helm 4, Kubectl, Trivy, and Cosign.

Do not place passwords or tokens in YAML. Use variable groups, Secure Files,
or workload identity and authorize them only for the pipelines that need them.

## 1. Create CI

Start from `pipelines/ci-frontendselfservicepos.yml`. Its build job calls
`build/job-buildcontainerizedservice.yml` with a `dockerImages` collection:

```yaml
jobs:
  - template: build/job-buildcontainerizedservice.yml
    parameters:
      displayName: Build Frontend Self Service POS
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

The template uses a BuildKit secret for NuGet configuration, restores committed
lock files in locked mode, exports the scratch `test-results` target directly
to the pipeline workspace, publishes TRX and Cobertura output, then pushes the
final image once with an immutable build tag. The same isolated Buildx builder
serves both operations, so the final build reuses the tested graph. Buildx
attaches SBOM/provenance and writes the pushed digest to the `image-metadata`
pipeline artifact.

## 2. Add the blocking PR security job

Use `security/job-securityscan.yml` when `Build.Reason` is `PullRequest` and
enable CodeQL, dependency scanning, license scanning, image scanning, and Helm
configuration scanning. The repository template deliberately fails the job for
HIGH/CRITICAL findings; do not add `continueOnError` to a release gate.

Set both success and failure PR statuses using
`pullrequest/step-setprstatus.yml`. Configure that status as a required branch
policy so merging cannot bypass the scan.

## 3. Create CD

Start from `pipelines/cd-frontendselfservicepos.yml`. Each stage calls the same
deployment job with a different environment and values artifact:

```yaml
- template: deploy/job-deployservicetok8s.yml
  parameters:
    container: worker
    environment: fastfood-$(stagename)
    namespace: $(namespace)
    valuesFile: $(helmChartArtifactValuesFileDownloadPath)
    artifactName: $(pipelineArtifactName)
    chartPackage: $(helmChartArtifactDownloadPath)
    kubernetesDeploymentServiceConnection: $(kubernetesDeploymentServiceConnection)
    updateBuildNumber: true
    pool:
      vmImage: ubuntu-24.04
```

The Helm step rolls back on failure and waits for workloads and migration Jobs.
Staging runs first; production depends on successful staging and should have an
Azure DevOps environment approval/check. Pull requests deploy to `pr-<id>`
independently and run the system-test verification job.

## 4. Promote immutable bytes

For a production-grade completion of the lab:

1. Download the CI `image-metadata` artifact.
2. Put its digest into the chart's `image.digest` value.
3. Sign and verify it with `security/step-signandverifyimage.yml`.
4. Require the signature in the cluster admission controller.
5. Enable `infrastructure/policies/require-image-digests.yaml` for production.

Never rebuild between staging and production. Promotion must reuse the digest
that passed tests and security gates.

## 5. Failure exercises

- Change a package version without updating `packages.lock.json`: restore fails.
- Break `/health/ready`: Helm times out and rolls back automatically.
- Add a critical vulnerable package or insecure Kubernetes setting: the
  security job fails.
- Attempt to deploy a tag into a digest-enforced namespace: admission denies it.
- Cancel deployment during rollout: inspect that Helm did not leave a partial
  release.

## Completion checklist

- Test and coverage artifacts are visible in Azure DevOps.
- The registry digest equals the digest in `image-metadata` and Helm values.
- No `latest` tag is produced by the service pipeline.
- Production approval and least-privilege service connections are configured.
- A failed release rolls back, and a closed PR triggers namespace cleanup.
