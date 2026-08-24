using Dapr.Client;
using FastFood.Common;
using Microsoft.AspNetCore.Mvc;

namespace OrderPlacement.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SecretDemoController : ControllerBase
{
    private readonly DaprClient _daprClient;
    private readonly IConfiguration _configuration;

    public SecretDemoController(DaprClient daprClient, IConfiguration configuration)
    {
        _daprClient = daprClient;
        _configuration = configuration;
    }
    
    [HttpGet("{key}")]
    public async Task<ActionResult<string>> GetSecret(string key, CancellationToken cancellationToken)
    {
        if (!_configuration.GetValue<bool>("Demos:SecretEndpoint:Enabled"))
        {
            return NotFound();
        }

        var allowedKeys = _configuration
            .GetSection("Demos:SecretEndpoint:AllowedKeys")
            .GetChildren()
            .Select(item => item.Value)
            .Where(value => !string.IsNullOrWhiteSpace(value));

        if (!allowedKeys.Contains(key, StringComparer.Ordinal))
        {
            return Forbid();
        }

        var secrets = await _daprClient.GetSecretAsync(
            FastFoodConstants.SecretStore,
            key,
            cancellationToken: cancellationToken);
        return Ok(secrets.Values.FirstOrDefault());
    }
}
