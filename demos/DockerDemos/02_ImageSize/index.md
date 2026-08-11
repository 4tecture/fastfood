# Image size demo

- Build and create container images
    - Run the script [run.sh](run.sh) which uses the [Dockerfile](Dockerfile)
- Compare the different image sizes

All four targets use the same framework-dependent application publish; the
comparison therefore isolates runtime-image choices. Alpine uses musl libc,
plain chiseled omits globalization data, and chiseled-extra includes ICU and
time-zone data. Native AOT is intentionally a separate compatibility topic:
this Dapr/EF Core application is not presented as AOT-compatible without a
dedicated test and dependency review.
