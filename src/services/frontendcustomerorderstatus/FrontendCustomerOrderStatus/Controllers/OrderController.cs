using FastFood.Common;
using FastFood.Common.ServiceInvocation;
using Microsoft.AspNetCore.Mvc;
using OrderService.Common.Dtos;

namespace FrontendCustomerOrderStatus.Controllers;

[ApiController]
[Route("api/[controller]")]
public partial class OrderController : ControllerBase
{
    private readonly IDaprServiceInvoker _serviceInvoker;
    private readonly ILogger<OrderController> _logger;
    private const string ApiPrefix = "api/orderstate";

    public OrderController(IDaprServiceInvoker serviceInvoker, ILogger<OrderController> logger)
    {
        _serviceInvoker = serviceInvoker;
        _logger = logger;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(Guid id)
    {
        try
        {
            using var request = _serviceInvoker.CreateInvokeMethodRequest(HttpMethod.Get, FastFoodConstants.Services.OrderService, $"{ApiPrefix}/{id}");
            var order = await _serviceInvoker.InvokeMethodAsync<OrderDto>(request, HttpContext?.RequestAborted ?? CancellationToken.None);
            return Ok(order);
        }
        catch
        {
            return StatusCode(500, "Failed to retrieve order.");
        }
    }
}
