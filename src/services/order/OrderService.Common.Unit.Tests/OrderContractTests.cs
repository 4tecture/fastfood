using System.Text.Json;
using OrderService.Common.Dtos;

namespace OrderService.Common.Unit.Tests;

public sealed class OrderContractTests
{
    [Fact]
    public void Order_JsonRoundTrip_PreservesEventContract()
    {
        var order = new OrderDto
        {
            Id = Guid.NewGuid(),
            OrderReference = "O987",
            Type = OrderDtoType.Delivery,
            State = OrderDtoState.Paid,
            CustomerComments = "Ring the bell",
            ServiceFee = 2.50m,
            Discount = 1.25m,
            Items = [new OrderItemDto { Id = Guid.NewGuid(), CustomerComments = "No salt" }]
        };

        var json = JsonSerializer.Serialize(order, JsonSerializerOptions.Web);
        var roundTripped = JsonSerializer.Deserialize<OrderDto>(json, JsonSerializerOptions.Web);

        Assert.NotNull(roundTripped);
        Assert.Equal(order.Id, roundTripped.Id);
        Assert.Equal(OrderDtoType.Delivery, roundTripped.Type);
        Assert.Equal(OrderDtoState.Paid, roundTripped.State);
        Assert.Equal(2.50m, roundTripped.ServiceFee);
        Assert.Equal(1.25m, roundTripped.Discount);
        Assert.Equal("Ring the bell", roundTripped.CustomerComments);
        Assert.Equal("No salt", Assert.Single(roundTripped.Items!).CustomerComments);
    }
}
