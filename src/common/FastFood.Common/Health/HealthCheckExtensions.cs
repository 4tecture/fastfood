using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FastFood.Common.Health;

/// <summary>
/// Provides consistent Kubernetes health endpoints for every FastFood service.
/// Liveness is deliberately dependency-free; readiness includes Dapr when enabled.
/// </summary>
public static class HealthCheckExtensions
{
    private const string LiveTag = "live";

    public static IServiceCollection AddFastFoodHealthChecks(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var checks = services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy(), tags: [LiveTag]);

        var checkDapr = !bool.TryParse(configuration["HealthChecks:CheckDapr"], out var enabled) || enabled;
        if (checkDapr)
        {
            checks.AddCheck<DaprOutboundHealthCheck>("dapr-outbound", tags: ["ready"]);
        }

        return services;
    }

    public static WebApplication MapFastFoodHealthChecks(this WebApplication app)
    {
        app.MapHealthChecks("/health/live", new HealthCheckOptions
        {
            Predicate = registration => registration.Tags.Contains(LiveTag)
        });
        app.MapHealthChecks("/health/ready", new HealthCheckOptions
        {
            Predicate = registration => !registration.Tags.Contains(LiveTag)
        });

        // Preserve the original dependency-free endpoint used by the standalone
        // Docker labs. Kubernetes readiness belongs exclusively to /health/ready.
        app.MapHealthChecks("/healthz", new HealthCheckOptions
        {
            Predicate = registration => registration.Tags.Contains(LiveTag)
        });
        return app;
    }
}

internal sealed class DaprOutboundHealthCheck : IHealthCheck
{
    private static readonly HttpClient Client = new()
    {
        Timeout = TimeSpan.FromSeconds(2)
    };

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var daprEndpoint = Environment.GetEnvironmentVariable("DAPR_HTTP_ENDPOINT");
            if (string.IsNullOrWhiteSpace(daprEndpoint))
            {
                var daprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500";
                daprEndpoint = $"http://127.0.0.1:{daprHttpPort}";
            }

            if (!Uri.TryCreate(daprEndpoint.TrimEnd('/') + "/v1.0/healthz/outbound", UriKind.Absolute, out var endpoint) ||
                (endpoint.Scheme != Uri.UriSchemeHttp && endpoint.Scheme != Uri.UriSchemeHttps))
            {
                return HealthCheckResult.Unhealthy("The Dapr HTTP endpoint is invalid.");
            }

            using var request = new HttpRequestMessage(HttpMethod.Get, endpoint);
            var apiToken = Environment.GetEnvironmentVariable("DAPR_API_TOKEN");
            if (!string.IsNullOrWhiteSpace(apiToken))
            {
                request.Headers.TryAddWithoutValidation("dapr-api-token", apiToken);
            }

            using var response = await Client.SendAsync(request, cancellationToken);
            return response.StatusCode is HttpStatusCode.NoContent or HttpStatusCode.OK
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy($"Dapr returned HTTP {(int)response.StatusCode}.");
        }
        catch (Exception exception) when (exception is HttpRequestException or TaskCanceledException)
        {
            return HealthCheckResult.Unhealthy("Dapr outbound endpoint is unavailable.", exception);
        }
    }
}
