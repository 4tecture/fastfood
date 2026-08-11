# Use the official ASP.NET Core runtime as a parent image
FROM mcr.microsoft.com/dotnet/sdk:10.0.302 AS build

# Expose port 8080 for the application
EXPOSE 8080

# Set the working directory in the container
WORKDIR /src
COPY ["Directory.Build.props", "."]

# Copy project files for different parts of the solution to enable caching of the restore step.
COPY ["common/FastFood.Common/FastFood.Common.csproj", "common/FastFood.Common/packages.lock.json", "common/FastFood.Common/"]
COPY ["common/FastFood.Observability.Common/FastFood.Observability.Common.csproj", "common/FastFood.Observability.Common/packages.lock.json", "common/FastFood.Observability.Common/"]
COPY ["services/finance/FinanceService/FinanceService.csproj", "services/finance/FinanceService/packages.lock.json", "services/finance/FinanceService/"]
COPY ["services/finance/FinanceService.Common/FinanceService.Common.csproj", "services/finance/FinanceService.Common/packages.lock.json", "services/finance/FinanceService.Common/"]
COPY ["services/finance/FinanceService.Storage/FinanceService.Storage.csproj", "services/finance/FinanceService.Storage/packages.lock.json", "services/finance/FinanceService.Storage/"]

# Restore all the project files
RUN --mount=type=cache,target=/root/.nuget/packages dotnet restore "services/finance/FinanceService/FinanceService.csproj" --locked-mode

# Source changes now invalidate only the build layer, not package restore.
COPY . .

# Reuse the restored packages while publishing. Cache mounts are not persisted in
# image layers, so every step that reads the NuGet package cache must mount it.
RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore


FROM mcr.microsoft.com/dotnet/aspnet:10.0.10-noble-chiseled-extra AS base

WORKDIR /app

COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID

# Define the entry point for the container
ENTRYPOINT ["dotnet", "FinanceService.dll"]
