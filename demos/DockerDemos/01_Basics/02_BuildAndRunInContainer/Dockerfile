# Use the official ASP.NET Core runtime as a parent image
FROM mcr.microsoft.com/dotnet/sdk:10.0.400 AS base

# Expose port 8080 for the application
EXPOSE 8080

# Set the working directory in the container
WORKDIR /src

# Copy the source code of the repository
COPY . .

# Build the FinanceService project in Release mode and output the build results to /app/build.
RUN dotnet restore "services/finance/FinanceService/FinanceService.csproj" --locked-mode
RUN dotnet build "services/finance/FinanceService/FinanceService.csproj" -c Release --no-restore
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore

# Run from the publish directory so ASP.NET Core loads appsettings.json and
# other content files copied there by dotnet publish.
WORKDIR /app/publish

# Define the entry point for the container
USER $APP_UID
ENTRYPOINT ["dotnet", "FinanceService.dll"]
