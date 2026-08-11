using System.Net;
using System.Text;
using FastFood.Common.ServiceInvocation;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FastFood.Common.Unit.Tests;

public sealed class DaprServiceInvokerTests
{
    [Theory]
    [InlineData("file:///tmp/dapr.sock", "10")]
    [InlineData("http://localhost:3500", "0")]
    [InlineData("http://localhost:3500", "301")]
    public void AddDaprServiceInvocation_RejectsUnsafeConfiguration(string endpoint, string timeout)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Dapr:HttpEndpoint"] = endpoint,
                ["Dapr:ServiceInvocationTimeoutSeconds"] = timeout
            })
            .Build();

        var services = new ServiceCollection();

        Assert.Throws<InvalidOperationException>(
            () => services.AddDaprServiceInvocation(configuration, defaultHttpPort: 3500));
    }

    [Fact]
    public void CreateInvokeMethodRequest_ValidatesRequiredRouteValues()
    {
        using var client = new HttpClient { BaseAddress = new Uri("http://localhost:3500/") };
        var sut = new DaprServiceInvoker(client);

        Assert.Throws<ArgumentException>(() => sut.CreateInvokeMethodRequest(HttpMethod.Get, " ", "orders/1"));
        Assert.Throws<ArgumentException>(() => sut.CreateInvokeMethodRequest(HttpMethod.Get, "orderservice", " "));
        Assert.Throws<ArgumentException>(() => sut.CreateInvokeMethodRequest(HttpMethod.Get, "orderservice", "../metadata"));
        Assert.Throws<ArgumentException>(() => sut.CreateInvokeMethodRequest(HttpMethod.Get, "orderservice", "api\\orders"));
    }

    [Fact]
    public async Task InvokeMethodAsync_UsesDaprRouteAndWebJsonDefaults()
    {
        HttpRequestMessage? capturedRequest = null;
        string? capturedBody = null;
        var handler = new StubHttpMessageHandler(async request =>
        {
            capturedRequest = request;
            capturedBody = request.Content is null
                ? null
                : await request.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{\"orderId\":42}", Encoding.UTF8, "application/json")
            };
        });
        using var client = new HttpClient(handler) { BaseAddress = new Uri("http://localhost:3500/") };
        var sut = new DaprServiceInvoker(client);

        using var request = sut.CreateInvokeMethodRequest(
            HttpMethod.Post,
            "order service",
            "/api/orders",
            new CreateOrder(42));
        var response = await sut.InvokeMethodAsync<OrderResponse>(request, TestContext.Current.CancellationToken);

        Assert.NotNull(capturedRequest);
        Assert.Equal(HttpMethod.Post, capturedRequest.Method);
        Assert.Equal("http://localhost:3500/v1.0/invoke/order%20service/method/api/orders", capturedRequest.RequestUri?.AbsoluteUri);
        Assert.Equal("{\"orderId\":42}", capturedBody);
        Assert.Equal(42, response.OrderId);
    }

    [Fact]
    public async Task InvokeMethodAsync_PropagatesNonSuccessStatus()
    {
        var handler = new StubHttpMessageHandler(_ => Task.FromResult(
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable)));
        using var client = new HttpClient(handler) { BaseAddress = new Uri("http://localhost:3500/") };
        var sut = new DaprServiceInvoker(client);
        using var request = sut.CreateInvokeMethodRequest(HttpMethod.Get, "orderservice", "api/orders/42");

        var exception = await Assert.ThrowsAsync<HttpRequestException>(
            () => sut.InvokeMethodAsync<OrderResponse>(request, TestContext.Current.CancellationToken));

        Assert.Equal(HttpStatusCode.ServiceUnavailable, exception.StatusCode);
    }

    [Fact]
    public async Task InvokeMethodAsync_DeserializesTheApplicationsStringEnumContract()
    {
        var handler = new StubHttpMessageHandler(_ => Task.FromResult(
            new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(
                    "{\"state\":\"Creating\"}",
                    Encoding.UTF8,
                    "application/json")
            }));
        using var client = new HttpClient(handler) { BaseAddress = new Uri("http://localhost:3500/") };
        var sut = new DaprServiceInvoker(client);
        using var request = sut.CreateInvokeMethodRequest(HttpMethod.Get, "orderservice", "api/orders/42");

        var response = await sut.InvokeMethodAsync<OrderStateResponse>(
            request,
            TestContext.Current.CancellationToken);

        Assert.Equal(TestOrderState.Creating, response.State);
    }

    private sealed record CreateOrder(int OrderId);
    private sealed record OrderResponse(int OrderId);
    private sealed record OrderStateResponse(TestOrderState State);
    private enum TestOrderState { Creating }

    private sealed class StubHttpMessageHandler(
        Func<HttpRequestMessage, Task<HttpResponseMessage>> responseFactory) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken) => responseFactory(request);
    }
}
