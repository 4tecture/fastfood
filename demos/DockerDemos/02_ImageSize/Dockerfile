# ----- Build Stage -----
FROM mcr.microsoft.com/dotnet/sdk:10.0.400 AS build
WORKDIR /src

# Install additional tools for AOT compilation
# RUN apt update
# RUN apt install -y clang zlib1g-dev

# Copy your project files
COPY . .

# Restore dependencies
RUN dotnet restore "services/finance/FinanceService/FinanceService.csproj" --locked-mode

# Standard publish (non-optimized)
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore

RUN find /app/publish -type d -exec chmod 755 {} \; && \
    find /app/publish -type f -exec chmod 644 {} \;

# ----- Runtime Targets -----

# 1. Standard runtime image using the default ASP.NET runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0.11 AS base_standard
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "FinanceService.dll"]
USER $APP_UID

# 2. Framework-dependent build on the Alpine-based ASP.NET runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0.11-alpine3.24 AS base_alpine
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "FinanceService.dll"]
USER $APP_UID

# 3. Framework-dependent build on the chiseled ASP.NET runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0.11-noble-chiseled AS base_chiseled
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "FinanceService.dll"]
USER $APP_UID

# 4. Chiseled-extra includes ICU and time-zone data for globalization support
FROM mcr.microsoft.com/dotnet/aspnet:10.0.11-noble-chiseled-extra AS base_chiseled_extra
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "FinanceService.dll"]
USER $APP_UID
