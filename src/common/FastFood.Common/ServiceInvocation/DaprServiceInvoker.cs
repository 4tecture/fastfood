using System.Net.Http.Json;
using System.Text.Json;
using FastFood.Common.Settings;

namespace FastFood.Common.ServiceInvocation;

internal sealed class DaprServiceInvoker : IDaprServiceInvoker
{
    private static readonly JsonSerializerOptions SerializerOptions =
        new JsonSerializerOptions(JsonSerializerDefaults.Web).ConfigureJsonSerializerOptions();
    private readonly HttpClient _httpClient;

    public DaprServiceInvoker(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public HttpRequestMessage CreateInvokeMethodRequest(HttpMethod method, string appId, string methodName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(appId);
        ArgumentException.ThrowIfNullOrWhiteSpace(methodName);

        var normalizedMethodName = methodName.TrimStart('/');
        var methodPath = normalizedMethodName.Split(['?', '#'], 2)[0];
        if (normalizedMethodName.Contains('\\') || normalizedMethodName.Contains('#') ||
            methodPath.Split('/').Any(segment => segment is "." or ".."))
        {
            throw new ArgumentException("The Dapr method route contains an invalid path segment.", nameof(methodName));
        }

        var requestUri = $"v1.0/invoke/{Uri.EscapeDataString(appId)}/method/{normalizedMethodName}";
        return new HttpRequestMessage(method, requestUri);
    }

    public HttpRequestMessage CreateInvokeMethodRequest<TRequest>(
        HttpMethod method,
        string appId,
        string methodName,
        TRequest data)
    {
        var request = CreateInvokeMethodRequest(method, appId, methodName);
        request.Content = JsonContent.Create(data, options: SerializerOptions);
        return request;
    }

    public async Task<TResponse> InvokeMethodAsync<TResponse>(
        HttpRequestMessage request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        using var response = await _httpClient.SendAsync(
            request,
            HttpCompletionOption.ResponseHeadersRead,
            cancellationToken);
        response.EnsureSuccessStatusCode();

        if (response.Content.Headers.ContentLength == 0)
        {
            return default!;
        }

        return await response.Content.ReadFromJsonAsync<TResponse>(SerializerOptions, cancellationToken)
            ?? throw new HttpRequestException("The Dapr service returned an empty JSON response.");
    }
}
