using System.Text.Json;
using KitchenService.Common.Dtos;

namespace KitchenService.Common.Unit.Tests;

public sealed class KitchenContractTests
{
    [Fact]
    public void KitchenOrder_JsonRoundTrip_PreservesEventContract()
    {
        var orderId = Guid.NewGuid();
        var itemId = Guid.NewGuid();
        var order = new KitchenOrderDto
        {
            Id = orderId,
            OrderReference = "O123",
            Items =
            [
                new KitchenOrderItemDto
                {
                    Id = itemId,
                    OrderId = orderId,
                    Quantity = 2,
                    CustomerComments = "No onions",
                    State = KitchenOrderItemDtoState.AwaitingPreparation
                }
            ]
        };

        var json = JsonSerializer.Serialize(order, JsonSerializerOptions.Web);
        var roundTripped = JsonSerializer.Deserialize<KitchenOrderDto>(json, JsonSerializerOptions.Web);

        Assert.NotNull(roundTripped);
        Assert.Equal(orderId, roundTripped.Id);
        Assert.Equal("O123", roundTripped.OrderReference);
        var item = Assert.Single(roundTripped.Items);
        Assert.Equal(itemId, item.Id);
        Assert.Equal("No onions", item.CustomerComments);
    }
}
