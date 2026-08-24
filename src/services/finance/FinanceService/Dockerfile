# Define build arguments for the base ASP.NET and SDK images and their versions.
# These arguments allow us to easily change the base images if needed.
ARG IMAGE_NET_ASPNET=mcr.microsoft.com/dotnet/aspnet
ARG IMAGE_NET_SDK=mcr.microsoft.com/dotnet/sdk
ARG IMAGE_NET_ASPNET_VERSION=10.0.11
ARG IMAGE_NET_SDK_VERSION=10.0.400

# Allow a suffix to be appended to the final ASP.NET image for development customizatio n.
# This can be overridden at build time with --build-arg ASPNET_SUFFIX=
ARG ASPNET_SUFFIX=-noble-chiseled-extra

# ---------------------------------------------------------------------
# Stage 1: Create the base runtime image from ASP.NET
# ---------------------------------------------------------------------

# Use the official ASP.NET runtime image with the specified version.
FROM ${IMAGE_NET_ASPNET}:${IMAGE_NET_ASPNET_VERSION}${ASPNET_SUFFIX} AS base
# Set the working directory in the container where the app will run.
WORKDIR /app
EXPOSE 8080
USER $APP_UID

# ---------------------------------------------------------------------
# Stage 2: Build the application
# ---------------------------------------------------------------------

# Use the .NET SDK image which includes tools for building the app.
FROM ${IMAGE_NET_SDK}:${IMAGE_NET_SDK_VERSION} AS build
# Set the working directory where the source code will be copied.
WORKDIR /src
COPY ["Directory.Build.props", "."]

# Copy project files for different parts of the solution to enable caching of the restore step.
COPY ["common/FastFood.Common/FastFood.Common.csproj", "common/FastFood.Common/packages.lock.json", "common/FastFood.Common/"]
COPY ["common/FastFood.Observability.Common/FastFood.Observability.Common.csproj", "common/FastFood.Observability.Common/packages.lock.json", "common/FastFood.Observability.Common/"]
COPY ["services/finance/FinanceService/FinanceService.csproj", "services/finance/FinanceService/packages.lock.json", "services/finance/FinanceService/"]
COPY ["services/finance/FinanceService.Storage/FinanceService.Storage.csproj", "services/finance/FinanceService.Storage/packages.lock.json", "services/finance/FinanceService.Storage/"]
COPY ["services/finance/FinanceService.Common/FinanceService.Common.csproj", "services/finance/FinanceService.Common/packages.lock.json", "services/finance/FinanceService.Common/"]
COPY ["services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj", "services/finance/FinanceService.Unit.Tests/packages.lock.json", "services/finance/FinanceService.Unit.Tests/"]
COPY ["services/finance/FinanceService.Common.Unit.Tests/FinanceService.Common.Unit.Tests.csproj", "services/finance/FinanceService.Common.Unit.Tests/packages.lock.json", "services/finance/FinanceService.Common.Unit.Tests/"]
ENV RestoreLockedMode=true

# Run dotnet restore for each project.
# If a secret NuGet configuration file is provided, it will be used during restore.
RUN --mount=type=secret,id=nugetconfig,required=false \
    sh -c 'set -eu; if [ -f /run/secrets/nugetconfig ]; then \
              dotnet restore --configfile /run/secrets/nugetconfig "common/FastFood.Common/FastFood.Common.csproj"; \
              dotnet restore --configfile /run/secrets/nugetconfig "common/FastFood.Observability.Common/FastFood.Observability.Common.csproj"; \
              dotnet restore --configfile /run/secrets/nugetconfig "services/finance/FinanceService/FinanceService.csproj"; \
              dotnet restore --configfile /run/secrets/nugetconfig "services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj"; \
              dotnet restore --configfile /run/secrets/nugetconfig "services/finance/FinanceService.Common.Unit.Tests/FinanceService.Common.Unit.Tests.csproj"; \
          else \
              dotnet restore "common/FastFood.Common/FastFood.Common.csproj"; \
              dotnet restore "common/FastFood.Observability.Common/FastFood.Observability.Common.csproj"; \
              dotnet restore "services/finance/FinanceService/FinanceService.csproj"; \
              dotnet restore "services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj"; \
              dotnet restore "services/finance/FinanceService.Common.Unit.Tests/FinanceService.Common.Unit.Tests.csproj"; \
          fi'

# Copy the remainder of the source code to the container.
COPY . .

# Publish the runtime payload once. The later publish stage inherits it through
# the test stage, so the final image is test-gated without compiling it again.
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore /p:UseAppHost=false
RUN dotnet build "services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj" -c Release --no-restore
RUN dotnet build "services/finance/FinanceService.Common.Unit.Tests/FinanceService.Common.Unit.Tests.csproj" -c Release --no-restore

# ---------------------------------------------------------------------
# Stage 3: Run tests
# ---------------------------------------------------------------------

FROM build AS test

# Execute tests for FinanceService.Common.Unit.Tests with code coverage.
RUN dotnet test --project services/finance/FinanceService.Common.Unit.Tests/FinanceService.Common.Unit.Tests.csproj --no-build -c Release --results-directory /testresults \
    --report-trx --report-trx-filename=test_results_financeservicecommon.trx \
    --coverlet --coverlet-file-prefix=financeservicecommon --coverlet-output-format=cobertura

# Execute tests for FinanceService.Unit.Tests with code coverage.
RUN dotnet test --project services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj --no-build -c Release --results-directory /testresults \
    --report-trx --report-trx-filename=test_results_financeservice.trx \
    --coverlet --coverlet-file-prefix=financeservice --coverlet-output-format=cobertura

# Export only the test evidence, rather than the complete SDK filesystem.
FROM scratch AS test-results
COPY --from=test /testresults /

# ---------------------------------------------------------------------
# Stage 4: Publish the application
# ---------------------------------------------------------------------

FROM test AS publish
# The tested stage already contains the published runtime payload.

# Modify file permissions: directories get 755 and files get 644 for better security and accessibility.
RUN find /app/publish -type d -exec chmod 755 {} \; && \
    find /app/publish -type f -exec chmod 644 {} \;

# ---------------------------------------------------------------------
# Stage 5: Create the final runtime image
# ---------------------------------------------------------------------

# Use the ASP.NET image with optional suffix applied.
FROM base AS final
# Set the working directory inside the container where the app will run.
WORKDIR /app

# Copy the published application from the publish stage into the final image.
COPY --from=publish /app/publish .

# Define the entry point of the container: run the FinanceService.dll using dotnet.
ENTRYPOINT ["dotnet", "FinanceService.dll"]
