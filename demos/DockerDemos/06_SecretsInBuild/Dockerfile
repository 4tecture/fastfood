# Use the official ASP.NET Core runtime as a parent image
FROM mcr.microsoft.com/dotnet/sdk:10.0.400 AS build

# Expose port 8080 for the application
EXPOSE 8080

# Set the working directory in the container
WORKDIR /src

# Copy the source code of the repository
COPY . .

# Build the FinanceService project in Release mode and output the build results to /app/build.
RUN --mount=type=secret,id=nugetconfig,required=true \
    dotnet restore --locked-mode --configfile /run/secrets/nugetconfig "services/finance/FinanceService/FinanceService.csproj"
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0.11-noble-chiseled-extra AS final

WORKDIR /app

COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID

# Define the entry point for the container
ENTRYPOINT ["dotnet", "FinanceService.dll"]
