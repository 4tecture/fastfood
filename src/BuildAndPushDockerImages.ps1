param (
    [string]$version = "0.1.0",
    [string]$registry = "yourregistry.azurecr.io"
)

# Function to build and push Docker images
function BuildAndPush-DockerImage {
    param (
        [string]$dockerfileDir,
        [string]$imageName
    )

    Write-Output "Building Docker image $imageName ..."
    $buildid = [guid]::NewGuid().ToString()
    $dockerfile = Join-Path $dockerfileDir "Dockerfile"
    $dockerfileContent = Get-Content -Path $dockerfile -Raw

    if ($dockerfileContent -match '(?m)^FROM\s+scratch\s+AS\s+test-results\s*$') {
        $safeImageName = $imageName -replace '[^A-Za-z0-9_.-]', '-'
        $testResultsDir = Join-Path "./TestResults" "$safeImageName/$buildid"
        New-Item -ItemType Directory -Path $testResultsDir -Force | Out-Null

        docker buildx build --file $dockerfile --target test-results --output "type=local,dest=$testResultsDir" .
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to export test results for $imageName"
        }

        $trxFiles = Get-ChildItem -Path $testResultsDir -Filter *.trx -Recurse
        $coverageFiles = Get-ChildItem -Path $testResultsDir -Filter *.coverage.cobertura.*.xml -Recurse
        if ($trxFiles.Count -eq 0 -or $coverageFiles.Count -eq 0) {
            throw "Expected TRX and Cobertura evidence was not exported for $imageName"
        }

        foreach ($trxFile in $trxFiles) {
            Write-Output "Reading test results from $($trxFile.FullName) ..."
            
            # Load the trx file and parse it as XML
            [xml]$trxContent = Get-Content $trxFile.FullName

            # Extract the statistics from the file
            $total = $trxContent.TestRun.ResultSummary.Counters.total
            $passed = $trxContent.TestRun.ResultSummary.Counters.passed
            $failed = $trxContent.TestRun.ResultSummary.Counters.failed

            Write-Output "Test Results for $($trxFile.Name): Total: $total, Passed: $passed, Failed: $failed"

            # Write an error if any tests failed
            if ($failed -gt 0) {
                throw "There are $failed failing tests in $($trxFile.Name)"
            }
        }
    }

    docker buildx build --load --tag $imageName --file $dockerfile --target final .

    if ($LASTEXITCODE -eq 0) {
        Write-Output "Pushing Docker image $imageName ..."
        #docker push $imageName

        if ($LASTEXITCODE -eq 0) {
            Write-Output "Successfully pushed $imageName"
        } else {
            Write-Error "Failed to push $imageName"
        }
    } else {
        Write-Error "Failed to build $imageName"
    }
}

# Get all service directories containing a Dockerfile.
$dockerfileDirs = Get-ChildItem -Path "./services" -Recurse -Filter Dockerfile | Select-Object -ExpandProperty DirectoryName

foreach ($dir in $dockerfileDirs) {
    $projectName = (Split-Path -Leaf $dir).ToLower()
    $imageName = "$($registry)/fastfood-$($projectName):$($version)"
    BuildAndPush-DockerImage -dockerfileDir $dir -imageName $imageName
}
