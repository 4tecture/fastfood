# Use the official ASP.NET Core runtime as a parent image
FROM mcr.microsoft.com/dotnet/sdk:10.0.400 AS build

# Expose port 8080 for the application
EXPOSE 8080

# Set the working directory in the container
WORKDIR /src

# Copy the source code of the repository
COPY . .

# Build the FinanceService project in Release mode and output the build results to /app/build.
RUN dotnet restore "services/finance/FinanceService/FinanceService.csproj" --locked-mode
RUN dotnet restore "services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj" --locked-mode
RUN dotnet build "services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj" -c Release --no-restore
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore

FROM build AS test

# Execute tests for FinanceService.Unit.Tests with code coverage.
RUN dotnet test --project services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj --no-build -c Release --results-directory /testresults \
    --report-trx --report-trx-filename=test_results_financeservice.trx \
    --coverlet --coverlet-file-prefix=financeservice --coverlet-output-format=cobertura

FROM scratch AS test-results
COPY --from=test /testresults /

FROM test AS publish
# Reuse the runtime payload published in the build stage; the inheritance from
# test keeps the final image gated on successful unit tests without rebuilding.

FROM mcr.microsoft.com/dotnet/aspnet:10.0.11-noble-chiseled-extra AS final

WORKDIR /app

COPY --from=publish /app/publish .
EXPOSE 8080
USER $APP_UID

# Define the entry point for the container
ENTRYPOINT ["dotnet", "FinanceService.dll"]
