﻿using Dapr.Client;
using Dapr.Workflow;
using FastFood.Common;
using OrderPlacement.Storages;
using OrderPlacement.Workflows.Events;
using OrderService.Models.Entities;
using OrderService.Models.Helpers;

namespace OrderPlacement.Workflows;

public partial class AddItemActivity : WorkflowActivity<AddItemEvent, Order>
{
    private readonly IOrderStorage _orderStorage;
    private readonly ILogger<AddItemActivity> _logger;
    private readonly DaprClient _daprClient;

    public AddItemActivity(IOrderStorage orderStorage, DaprClient daprClient, ILogger<AddItemActivity> logger)
    {
        _orderStorage = orderStorage;
        _daprClient = daprClient;
        _logger = logger;
    }

    public override async Task<Order> RunAsync(WorkflowActivityContext context, AddItemEvent input)
    {
        var order = await _orderStorage.GetOrderById(input.OrderId);
        if (order != null && order.State == OrderState.Creating)
        {
            var existingItem = order.Items?.FirstOrDefault(i => i.Id == input.Item.Id);
            if (existingItem != null)
            {
                // item already exists, idempotent operation
                return order;
            }
            else
            {
                order.Items.Add(input.Item);
                await _orderStorage.UpdateOrder(order);
                await _daprClient.PublishEventAsync(FastFoodConstants.PubSubName, FastFoodConstants.EventNames.OrderUpdated, order.ToDto());
                LogAddedItem(context.InstanceId, order.Id, input.Item.Id);
            }
        }
        else
        {
            LogAddedItemFailed(context.InstanceId, input.OrderId, input.Item.Id);
        }

        return order;
    }

    [LoggerMessage(EventId = 1, Level = LogLevel.Information, Message = "[Workflow {instanceId}] Added item {itemId} to order {orderId}")]
    private partial void LogAddedItem(string instanceId, Guid orderId, Guid itemId);

    [LoggerMessage(EventId = 2, Level = LogLevel.Error, Message = "[Workflow {instanceId}] Failed to add item {itemId} to order {orderId}")]
    private partial void LogAddedItemFailed(string instanceId, Guid orderId, Guid itemId);
}