# Hands-On Lab: Pull Request Environments, Status Checks, and Cleanup in Azure Pipelines

## Overview

In this lab, you will:
- Learn how PR (Pull Request) environments are handled in the deployment pipelines.
- Understand the dependencies between Staging, Production, and PullRequest stages in your CD pipelines.
- See how to add custom PR status checks using a step template.
- Learn how to automatically clean up PR environments using webhook triggers and a dedicated cleanup pipeline.
- Get full code examples for all templates and pipelines involved.

**Goal:** By the end of this lab, you will know how to implement robust PR deployment, verification, and cleanup in Azure Pipelines.

---

## Prerequisite: Install the deployment RBAC once

Run the cluster bootstrap with an administrator context before the lab:

```bash
infrastructure/ClusterPermissions/create-deployment-sa.sh
```

The script preserves the `cicd/deployment-sa` identity used by the existing
`k8sdemo-deployment` Azure DevOps service connection. It replaces the legacy
cluster-admin-like grant with:

- a reusable release ClusterRole that is granted one namespace at a time;
- a small PR namespace lifecycle role; and
- admission policies that only allow `pr-<positive id>` namespaces and the
  approved release RoleBinding.

See `infrastructure/ClusterPermissions/README.md` for the authorization model
and admission-policy API compatibility notes.

---

## Step 1: Understanding Staging, Production, and PullRequest Stages

Every CD pipeline (e.g., `cd-frontendselfservicepos.yml`) is structured with multiple stages:
- **Staging:** Deploys to a shared staging environment, usually only for the `main` branch.
- **Production:** Deploys to production, but only after staging has succeeded. This stage depends on Staging.
- **PullRequest:** Deploys a temporary environment for each PR, using a unique namespace. This stage is triggered only for PR builds and is independent of Staging/Production.

**Example from `cd-frontendselfservicepos.yml`:**
```yaml
stages:
  - stage: Staging
    condition: and(succeeded(), eq(variables['Build.SourceBranchName'], 'main'))
    # ...
  - stage: Production
    dependsOn: Staging
    condition: and(succeeded(), eq(variables['Build.SourceBranchName'], 'main'))
    # ...
  - stage: PullRequest
    dependsOn: []
    condition: and(succeeded(), startsWith(variables['resources.pipeline.CIBuild.sourceBranch'], 'refs/pull/'))
    variables:
      - name: pullRequestId
        value: $[replace(replace(variables['resources.pipeline.CIBuild.sourceBranch'], 'refs/pull/', ''), '/merge', '')]
    # ...
```
**Explanation:**
- **Staging** and **Production** only run for the `main` branch, and Production only runs if Staging succeeds.
- **PullRequest** runs only when its CI pipeline resource was built from a
  `refs/pull/<id>/merge` branch and is independent of the other stages. The
  initializer itself is a direct branch-policy build and can use
  `System.PullRequest.PullRequestId`; downstream CD pipelines derive the same
  ID from `resources.pipeline.CIBuild.sourceBranch` at runtime.

---

## Step 2: Deploying and Testing PR Environments

In the PullRequest stage, a unique namespace is created for each PR (e.g.,
`pr-123`). Namespace creation uses `kubectl apply --server-side`, so the PR
initializer and service CD pipelines may safely bootstrap the namespace at the
same time. Each pipeline also applies the namespace-local release RoleBinding.

The shared bootstrap validates the runtime PR ID and derives a Redis database
with `(pullRequestId % 13) + 3`. Databases 0-2 remain reserved and PRs use
3-15. It labels the namespace with that assignment and fails if another active
PR namespace already uses the same database. Dapr state and pub/sub both use
the selected database, while namespace key prefixes and consumer IDs provide a
second layer of isolation.

Azure DevOps build validations start in parallel. A service CD pipeline waits
for `pr-initialize` to install that service's main-branch baseline release, then
upgrades it with the PR artifact. This ordering prevents two subtle races:

- Helm cannot operate on a namespace that has not been created yet.
- A late baseline installation must not overwrite the PR-specific artifact.

The initializer selects the latest successful `main` pipeline resource and
deploys its stable version tag. It does not require the newer image-metadata
artifact from that historical build. The service-specific PR CD pipeline then
replaces the changed service with the PR image pinned by its CI-produced
digest.

The deployment job otherwise uses the same Helm template as Staging and
Production, with PR-specific variables.

**Example PR stage in a CD pipeline:**
```yaml
- stage: PullRequest
  dependsOn: []
  condition: and(succeeded(), startsWith(variables['resources.pipeline.CIBuild.sourceBranch'], 'refs/pull/'))
  variables:
    - name: stagename
      value: pr
    - name: pullRequestId
      value: $[replace(replace(variables['resources.pipeline.CIBuild.sourceBranch'], 'refs/pull/', ''), '/merge', '')]
    - name: namespace
      value: $(stagename)-$(pullRequestId)
  jobs:
    - template: deploy/job-deployservicetok8s.yml
      parameters:
        environment: 'fastfood-$(stagename)'
        namespace: '$(namespace)'
        valuesFile: '$(helmChartArtifactValuesFileDownloadPath)'
        artifactName: '$(pipelineArtifactName)'
        chartPackage: '$(helmChartArtifactDownloadPath)'
        kubernetesDeploymentServiceConnection: '$(kubernetesDeploymentServiceConnection)'
        updateBuildNumber: true
        bootstrapPrEnvironment: true
        pullRequestId: '$(pullRequestId)'
        
        pool:
          vmImage: 'ubuntu-24.04'
    - template: deploy/job-verifyprdeployment.yml
      parameters:
        serviceName: '$(serviceName)'
        displayName: 'Run System Tests for PR $(pullRequestId)'
        pullRequestId: '$(pullRequestId)'
        pool:
          vmImage: 'ubuntu-24.04'
```
**Explanation:**
- The deployment job creates a PR-specific environment.
- The verification job runs system tests or other checks against the deployed PR environment.
- CD pipelines use `resources.pipeline.CIBuild.sourceBranch` because pipeline
  completion runs have `Build.Reason=ResourceTrigger`; Azure DevOps does not
  populate `System.PullRequest.*` for those downstream runs.
- Runtime values are calculated once in the shared bootstrap. This keeps the
  initializer and all service CD pipelines consistent rather than duplicating
  the Redis calculation in one pipeline.

---

## Step 3: Adding Custom PR Status Checks

You can add custom status checks to your PRs using a step template. This allows you to report the status of deployments, tests, or any other checks directly to the PR in Azure DevOps.

### 3.1. Step Template: Set PR Status

File: `pipelines/pullrequest/step-setprstatus.yml`

**Purpose:**
- Posts a status (e.g., success, failure, pending) to the PR using the Azure DevOps REST API.
- Can be used after deployment, tests, or any custom logic.

**Parameters:**
- `contextName`: Name of the status context (e.g., "PR Deployment").
- `state`: State to set (`pending`, `succeeded`, `failed`).
- `description`: Description for the status.
- `targetUrl`: (Optional) Link to build or test results.
- `genre`, `iterationId`: (Optional) Advanced context.

**Example usage:**
```yaml
- template: pullrequest/step-setprstatus.yml
  parameters:
    contextName: 'PR Deployment'
    state: 'succeeded'
    description: 'PR environment deployed and tested successfully.'
    targetUrl: '$(System.TeamFoundationCollectionUri)$(System.TeamProject)/_build/results?buildId=$(Build.BuildId)'
```
**What to do:**
- Add this step after your PR deployment and test jobs to report the result to the PR.

---

## Step 4: Cleaning Up PR Environments with Webhook Triggers

When a PR is closed or abandoned, you should clean up the temporary namespace and resources. This is done using a webhook trigger and a dedicated cleanup pipeline.

### 4.1. Webhook Setup

- Configure an incoming webhook in Azure DevOps that triggers on PR updates (e.g., completed or abandoned events).
- The webhook triggers the `pr-cleanup.yml` pipeline and passes PR details as parameters.

### 4.2. Cleanup Pipeline: `pr-cleanup.yml`

**File:** `pipelines/pr-cleanup.yml`

**Purpose:**
- Deletes the PR's Azure SQL database and both workload identities.
- Deletes the Kubernetes namespace when the PR is completed or abandoned.
- Treats already-absent resources as success, so webhook retries are safe.
- Continues with the remaining cleanup actions if one resource reports an
  error, while still leaving the pipeline visibly failed for investigation.

**Full Example:**
```yaml
trigger: none

variables:
  - template: config/var-pool.yml
  - template: config/var-commonvariables.yml
  - template: config/var-commonvariables-release.yml
  - group: fastfood-releasesecrets

resources:
  webhooks:
    - webhook: fastfoodPrUpdated
      connection: FastfoodPREventsConnection
      filters:
      - path: eventType
        value: git.pullrequest.updated
      - path: publisherId
        value: tfs
      - path: resource.repository.name
        value: FastFood
  containers:
    - container: worker
      image: $(azureContainerRegistry)/fastfood-buildenv:$(NetCoreSdkVersion)
      endpoint: 4taksDemoAcr

jobs:
  - job: prCleanup
    displayName: 'PR Cleanup'
    condition: or(eq('${{ parameters.fastfoodPrUpdated.resource.status }}', 'completed'), eq('${{ parameters.fastfoodPrUpdated.resource.status }}', 'abandoned'))
    pool:
      vmImage: 'ubuntu-24.04'
    steps:
    - checkout: none
    - bash: |
        set -euo pipefail
        if [[ ! "$FASTFOOD_PR_ID" =~ ^[1-9][0-9]*$ ]]; then
          echo "Refusing cleanup for invalid pull request id." >&2
          exit 1
        fi
        echo "##vso[task.setvariable variable=validatedPullRequestId]$FASTFOOD_PR_ID"
        echo "##vso[task.setvariable variable=prIdValidated]true"
      displayName: 'Validate cleanup request'
      env:
        FASTFOOD_PR_ID: '${{ parameters.fastfoodPrUpdated.resource.pullRequestId }}'
    - template: deploy/step-deletedbazuresql.yml
      parameters:
        AzureSubscription: '$(azureSubscription)'
        ResourceGroup: '$(azureResourceGroup)'
        AzureSqlName: '$(sqlServerName)'
        DbName: 'FastFoodFinance-pr$(validatedPullRequestId)'
        condition: and(always(), eq(variables['prIdValidated'], 'true'))
    - template: deploy/step_deleteazuremanagedidentity.yml
      parameters:
        AzureSubscription: '$(azureSubscription)'
        ManagedIdentity: 'financeservice-pr-$(validatedPullRequestId)-smi'
        ManagedIdentityResourceGroup: '$(azureResourceGroup)'
        condition: and(always(), eq(variables['prIdValidated'], 'true'))
    - template: deploy/step_deleteazuremanagedidentity.yml
      parameters:
        AzureSubscription: '$(azureSubscription)'
        ManagedIdentity: 'financeservice-pr-$(validatedPullRequestId)-dmi'
        ManagedIdentityResourceGroup: '$(azureResourceGroup)'
        condition: and(always(), eq(variables['prIdValidated'], 'true'))
    - task: Kubernetes@1
      displayName: 'Delete PR Kubernetes Namespace'
      condition: and(always(), eq(variables['prIdValidated'], 'true'))
      inputs:
        connectionType: 'Kubernetes Service Connection'
        kubernetesServiceEndpoint: $(kubernetesDeploymentServiceConnection)
        command: delete
        arguments: 'namespace pr-$(validatedPullRequestId) --ignore-not-found=true --wait=false'
```
**Explanation:**
- The pipeline is triggered by a webhook when a PR is updated.
- It checks if the PR is completed or abandoned, and if so, deletes the corresponding Kubernetes namespace.

---

## Step 5: Summary

- **Staging** and **Production** stages are used for mainline deployments, with Production depending on Staging.
- **PullRequest** stage is used for PR validation, deploying to a unique namespace and running verification jobs.
- PR namespaces have isolated Dapr state/pub-sub configuration. The shared
  Redis instance provides 13 PR database slots; PR IDs with the same modulo-13
  assignment cannot be active together. Cleanup must remove closed PR
  namespaces before a colliding assignment can be reused.
- Custom PR status checks can be posted using a step template and the Azure DevOps REST API.
- PR namespaces and their external Azure resources are automatically cleaned up
  using an idempotent webhook-triggered pipeline.

This approach ensures that every PR is validated in isolation, results are visible in the PR, and resources are cleaned up automatically.

If you need help with PR environments, webhooks, or status checks, refer to the official Azure DevOps documentation or ask your instructor.
