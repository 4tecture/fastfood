# Container hardening demo

## Non-root user with limited permissions

- Build and create a container 
  - Run the script [BaseImage/run.sh](BaseImage/run.sh) which uses the [BaseImage/Dockerfile](BaseImage/Dockerfile)
- Run the container
  ```
  docker run --rm --name demohardening \
    --publish 127.0.0.1:8080:8080 \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=16m \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --env FeatureManagement__UseInMemoryDatabase=true \
    --env HealthChecks__CheckDapr=false \
    financeservice-demo-hardening
  ```
- Verify that the container is running
  - Open the URL [http://localhost:8080/healthz](http://localhost:8080/healthz)
  - Open the URL [http://localhost:8080/api/revenuereport/ByYear/2025](http://localhost:8080/api/revenuereport/ByYear/2025)

## Using a chiseled image

- Build and create a container 
  - Run the script [Chiseled/run.sh](Chiseled/run.sh) which uses the [Chiseled/Dockerfile](Chiseled/Dockerfile)
- Run the container
  ```
  docker run --rm --name demochiseled \
    --publish 127.0.0.1:8080:8080 \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=16m \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --env FeatureManagement__UseInMemoryDatabase=true \
    --env HealthChecks__CheckDapr=false \
    financeservice-demo-hardening-chiseled
  ```
- Verify that the container is running
  - Open the URL [http://localhost:8080/healthz](http://localhost:8080/healthz)
  - Open the URL [http://localhost:8080/api/revenuereport/ByYear/2025](http://localhost:8080/api/revenuereport/ByYear/2025)

## Explanation of Hardening and Image Differences

### Hardened Base Image
- Additional Security Steps:
  The hardened base image uses the non-root `app` user already provided by the official .NET image. The run script also enforces a read-only filesystem, drops Linux capabilities and enables `no-new-privileges`.
- Non-root Execution:
  The base image demo uses `USER $APP_UID`; it does not create another user with distribution-specific package tools.
- Flexibility:
  Since this image might include additional tools (like shells or package managers) for troubleshooting, it provides a good balance between security and operational flexibility during development or debugging.

### Chiseled Image
- Distroless Approach:
  The chiseled image is a distroless variant designed by Microsoft. It includes only the essential libraries and runtime components needed to run your ASP.NET Core application.
-  Enhanced Security by Default:
  Chiseled images run as a non‑root user out-of-the-box and intentionally omit unnecessary components such as shells or package managers. This greatly reduces the attack surface and minimizes potential vulnerabilities.
- Minimal Footprint:
  Due to the removal of extraneous packages, the chiseled image has a smaller size and faster startup time, which is ideal for production environments where security and performance are critical.

### Summary
Both approaches enhance container security, but they serve slightly different purposes:
- Hardened Base Image: Offers additional hardening on top of a standard runtime image and retains some flexibility for debugging.
- Chiseled Image: Provides a highly secure, minimalistic environment that is optimized for production use and minimizes potential attack vectors.
