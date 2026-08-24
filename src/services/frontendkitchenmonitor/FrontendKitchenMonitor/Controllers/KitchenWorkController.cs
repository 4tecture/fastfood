using System.Net;
using FastFood.Common;
using FastFood.Common.ServiceInvocation;
using KitchenService.Common.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace FrontendKitchenMonitor.Controllers;

[ApiController]
[Route("api/[controller]")]
public class KitchenWorkController : ControllerBase
{
    private readonly IDaprServiceInvoker _serviceInvoker;
    private readonly ILogger<KitchenWorkController> _logger;
    private const string ApiPrefix = "api/kitchenwork";


    public KitchenWorkController(IDaprServiceInvoker serviceInvoker, ILogger<KitchenWorkController> logger)
    {
        _serviceInvoker = serviceInvoker;
        _logger = logger;
    }
    
    // returns all pending order
    [HttpGet("pendingorders")]
    public async Task<ActionResult<IEnumerable<KitchenOrderDto>>> GetPendingOrders()
    {
        try
        {
            using var request = _serviceInvoker.CreateInvokeMethodRequest(HttpMethod.Get, FastFoodConstants.Services.KitchenService, $"{ApiPrefix}/pendingorders");
            var order = await _serviceInvoker.InvokeMethodAsync<IEnumerable<KitchenOrderDto>>(request, HttpContext?.RequestAborted ?? CancellationToken.None);
            return Ok(order);
        }
        catch
        {
            return StatusCode(500, "Failed to retrieve order.");
        }
    }
    
    [HttpGet("pendingorder/{id}")]
    public async Task<ActionResult<KitchenOrderDto>> GetPendingOrder(Guid id)
    {
        try
        {
            using var request = _serviceInvoker.CreateInvokeMethodRequest(HttpMethod.Get, FastFoodConstants.Services.KitchenService, $"{ApiPrefix}/pendingorder/{id}");
            var order = await _serviceInvoker.InvokeMethodAsync<KitchenOrderDto>(request, HttpContext?.RequestAborted ?? CancellationToken.None);
            return Ok(order);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return NotFound("Order not found or is not pending.");
        }
        catch(Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve order.");
            return StatusCode(500, "Failed to retrieve order.");
        }
    }

    // returns all pending items
    [HttpGet("pendingitems")]
    public async Task<ActionResult<IEnumerable<KitchenOrderItemDto>>> GetPendingItems()
    {
        try
        {
            using var request = _serviceInvoker.CreateInvokeMethodRequest(HttpMethod.Get, FastFoodConstants.Services.KitchenService, $"{ApiPrefix}/pendingitems");
            var order = await _serviceInvoker.InvokeMethodAsync<IEnumerable<KitchenOrderItemDto>>(request, HttpContext?.RequestAborted ?? CancellationToken.None);
            return Ok(order);
        }
        catch
        {
            return StatusCode(500, "Failed to retrieve order.");
        }
    }

    // sets an item as finished
    [HttpPost("itemfinished/{id}")]
    public async Task<ActionResult<KitchenOrderItemDto>> SetItemAsFinished(Guid id)
    {
        try
        {
            using var request = _serviceInvoker.CreateInvokeMethodRequest(HttpMethod.Post, FastFoodConstants.Services.KitchenService, $"{ApiPrefix}/itemfinished/{id}");
            var item = await _serviceInvoker.InvokeMethodAsync<KitchenOrderItemDto>(request, HttpContext?.RequestAborted ?? CancellationToken.None);
            return Ok(item);
        }
        catch
        {
            return StatusCode(500, "Failed to retrieve order.");
        }
    }
}
