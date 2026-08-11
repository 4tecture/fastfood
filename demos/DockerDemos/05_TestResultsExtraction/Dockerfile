# Use the official ASP.NET Core runtime as a parent image
FROM mcr.microsoft.com/dotnet/sdk:10.0.302 AS build

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
# Accept a build ID as an argument to label the test results; defaults to "localbuild".
ARG BUILDID=localbuild
# Label the container with the build ID for test results traceability.
LABEL testresults=${BUILDID}

# Execute tests for FinanceService.Unit.Tests with code coverage.
RUN dotnet test services/finance/FinanceService.Unit.Tests/FinanceService.Unit.Tests.csproj --no-build -c Release --results-directory /testresults \
    --logger "trx;LogFileName=test_results_financeservice.trx" \
    --collect:"XPlat Code Coverage"

FROM mcr.microsoft.com/dotnet/aspnet:10.0.10-noble-chiseled-extra AS final

WORKDIR /app

COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID

# Define the entry point for the container
ENTRYPOINT ["dotnet", "FinanceService.dll"]
