namespace FastFood.Common.ServiceInvocation;

/// <summary>
/// Invokes an application through the local Dapr HTTP sidecar using the native
/// <see cref="HttpClient"/> stack recommended by current Dapr SDK guidance.
/// </summary>
public interface IDaprServiceInvoker
{
    HttpRequestMessage CreateInvokeMethodRequest(HttpMethod method, string appId, string methodName);

    HttpRequestMessage CreateInvokeMethodRequest<TRequest>(
        HttpMethod method,
        string appId,
        string methodName,
        TRequest data);

    Task<TResponse> InvokeMethodAsync<TResponse>(
        HttpRequestMessage request,
        CancellationToken cancellationToken = default);
}
