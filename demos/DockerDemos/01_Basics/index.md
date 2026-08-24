# Docker basics

These four labs build the same Finance service while progressively improving
the image. Every `run.sh` is location-independent and finishes with a hardened
smoke test against `/health/live`.

## 1. Publish on the host, copy into a runtime image

```bash
./01_CompileAndCopyToContainer/run.sh
```

Discuss why a host publish is easy to understand but couples the build to the
developer workstation. Inspect the image history and the explicit non-root
runtime user.

## 2. Build inside the container

```bash
./02_BuildAndRunInContainer/run.sh
```

This is intentionally a single-stage SDK image. Compare its size and attack
surface with the next lab; it is a teaching intermediate, not a production
image.

## 3. Multi-stage build

```bash
./03_Multistage/run.sh
```

Only published output crosses into the ASP.NET runtime stage. The SDK, source,
NuGet cache, and test tools do not ship in the final image.

## 4. Restore-layer caching

```bash
./04_Caching/run.sh
```

Project metadata is copied before source, and the restore uses a BuildKit cache
mount. Repeat the build after changing a `.cs` file, then after changing a
project or lock file, and compare which layers invalidate.

## Manual runtime inspection

The scripts remove their smoke-test containers. To keep one running for
inspection, use the same restrictions explicitly:

```bash
docker run --rm \
  --name finance-demo \
  --publish 127.0.0.1:8080:8080 \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --env FeatureManagement__UseInMemoryDatabase=true \
  --env HealthChecks__CheckDapr=false \
  financeservice-demo-caching
```

Then verify `http://127.0.0.1:8080/health/live`. Compare this with an
unrestricted container only as an instructor-led security exercise.
