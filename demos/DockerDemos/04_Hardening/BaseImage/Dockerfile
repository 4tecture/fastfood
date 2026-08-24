# -------------------------------
# Stage 1: Build Stage
# -------------------------------
# Use the official .NET SDK image to build the application.
FROM mcr.microsoft.com/dotnet/sdk:10.0.400 AS build

# Set the working directory in the build container.
WORKDIR /src

# Copy all source code to the container.
COPY . .

# Restore NuGet packages for the FinanceService project.
RUN dotnet restore "services/finance/FinanceService/FinanceService.csproj" --locked-mode

# Build the FinanceService project in Release mode.
RUN dotnet publish "services/finance/FinanceService/FinanceService.csproj" -c Release -o /app/publish --no-restore


# -------------------------------
# Stage 2: Runtime (Final) Stage
# -------------------------------
# Use the official ASP.NET Core runtime image for the final container.
FROM mcr.microsoft.com/dotnet/aspnet:10.0.11 AS runtime

# Add metadata labels for maintainability and traceability.
LABEL maintainer="Your Name <you@example.com>" \
      version="1.0" \
      description="Hardened Docker image for FinanceService"

# Set the working directory to /app.
WORKDIR /app

# Copy the published application from the build stage.
COPY --from=build /app/publish .

# Expose the port that the application listens on.
EXPOSE 8080

# Switch to the non-root user to run the application.
USER $APP_UID

# Note: For additional hardening at runtime, consider running the container with a read-only filesystem.
# This can be enforced via Docker run options:
#    docker run --read-only -p 8080:8080 financeservice-demo-hardening
# Other runtime security options (e.g., seccomp, AppArmor profiles) can be applied at deployment time.

# Define the entry point for the container.
ENTRYPOINT ["dotnet", "FinanceService.dll"]
