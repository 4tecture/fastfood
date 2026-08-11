using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FastFood.Common.ServiceInvocation;

public static class ServiceInvocationExtensions
{
    public static IServiceCollection AddDaprServiceInvocation(
        this IServiceCollection services,
        IConfiguration configuration,
        int defaultHttpPort)
    {
        var endpoint = configuration["Dapr:HttpEndpoint"]
            ?? Environment.GetEnvironmentVariable("DAPR_HTTP_ENDPOINT")
            ?? $"http://localhost:{Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? defaultHttpPort.ToString()}";

        if (!Uri.TryCreate(endpoint, UriKind.Absolute, out var baseAddress) ||
            (baseAddress.Scheme != Uri.UriSchemeHttp && baseAddress.Scheme != Uri.UriSchemeHttps))
        {
            throw new InvalidOperationException("Dapr:HttpEndpoint must be an absolute HTTP or HTTPS URI.");
        }

        var timeoutSeconds = configuration.GetValue("Dapr:ServiceInvocationTimeoutSeconds", 10);
        if (timeoutSeconds is < 1 or > 300)
        {
            throw new InvalidOperationException("Dapr:ServiceInvocationTimeoutSeconds must be between 1 and 300.");
        }

        services.AddHttpClient<IDaprServiceInvoker, DaprServiceInvoker>(client =>
        {
            client.BaseAddress = new Uri(baseAddress.ToString().TrimEnd('/') + "/");
            client.Timeout = TimeSpan.FromSeconds(timeoutSeconds);

            var apiToken = Environment.GetEnvironmentVariable("DAPR_API_TOKEN");
            if (!string.IsNullOrWhiteSpace(apiToken))
            {
                client.DefaultRequestHeaders.Add("dapr-api-token", apiToken);
            }
        });

        return services;
    }
}
