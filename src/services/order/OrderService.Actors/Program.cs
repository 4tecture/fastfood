using System.Text.Json;
using System.Text.Json.Serialization;
using FastFood.Common.Settings;
using FastFood.Observability.Common;
using FinanceService.Observability;
using OrderPlacement.Actors;

var builder = WebApplication.CreateBuilder(args);

var observabilityOptions = builder.Configuration.GetObservabilityOptions();
builder.Services.AddObservability<IOrderServiceActorObservability, OrderServiceActorObservability>(observabilityOptions, options => new OrderServiceActorObservability(options.ServiceName, options.ServiceName));

var daprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3650";
var daprGrpcPort = Environment.GetEnvironmentVariable("DAPR_GRPC_PORT") ?? "60650";
builder.Services.AddDaprClient(builder => builder
    .UseHttpEndpoint($"http://localhost:{daprHttpPort}")
    .UseGrpcEndpoint($"http://localhost:{daprGrpcPort}")
    .UseJsonSerializationOptions(new JsonSerializerOptions().ConfigureJsonSerializerOptions()));

builder.Services.AddActors(options => { options.Actors.RegisterActor<OrderActor>(); });


builder.Services.AddControllers()
    .AddJsonOptions(options => { options.JsonSerializerOptions.ConfigureJsonSerializerOptions(); })
    .AddDapr();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCloudEvents();

app.UseObservability(observabilityOptions);

app.MapControllers();
app.MapSubscribeHandler();

app.MapActorsHandlers();

app.MapHealthChecks("/healthz");

app.Run();