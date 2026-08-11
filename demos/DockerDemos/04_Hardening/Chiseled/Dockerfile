# -------------------------------
# Stage 1: Build Stage
# -------------------------------
# Use the official .NET SDK image to build the application.
FROM mcr.microsoft.com/dotnet/sdk:10.0.302 AS build

# Set the working directory in the build container.
WORKDIR /src

# Copy all source code to the container.
COPY . .

# Restore NuGet packages for the FinanceService project.
RUN dotnet restore "services/finance/FinanceService/FinanceService.csproj" --locked-mode

# Build the FinanceService project in Release mode.
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore

# Modify file permissions: directories get 755 and files get 644 for better security and accessibility.
RUN find /app/publish -type d -exec chmod 755 {} \; && \
    find /app/publish -type f -exec chmod 644 {} \;


# -------------------------------
# Stage 2: Runtime (Final) Stage
# -------------------------------
# Use the official ASP.NET Core chiseled runtime image for the final container.
FROM mcr.microsoft.com/dotnet/aspnet:10.0.10-noble-chiseled-extra AS runtime

# Set the working directory to /app.
WORKDIR /app

# Copy the published application from the build stage.
COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID

ENTRYPOINT ["dotnet", "FinanceService.dll"]
