# Test Result Extraction

- Build and create a container
    - Run the script [run.sh](run.sh) which uses the [Dockerfile](Dockerfile)
    - The Dockerfile runs unit tests in a named `test` stage.
    - A scratch `test-results` stage exposes only TRX and Cobertura files.
    - Buildx writes that stage directly to the host with the local output exporter; no temporary image or container is required.
    - The runtime payload is published once in `build`; `publish` inherits from `test`, so the final image is test-gated without compiling the application again.
- The test results are now available outside of the container and can be integrated into your Azure DevOps Test Run Results.
