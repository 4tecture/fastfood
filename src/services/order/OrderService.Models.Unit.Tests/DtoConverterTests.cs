using OrderService.Models.Entities;
using OrderService.Models.Helpers;

namespace OrderService.Models.Unit.Tests;

public sealed class DtoConverterTests
{
    [Fact]
    public void OrderDtoRoundTrip_PreservesThePublicOrderContract()
    {
        var orderId = Guid.NewGuid();
        var itemId = Guid.NewGuid();
        var productId = Guid.NewGuid();
        var customerId = Guid.NewGuid();
        var entity = new Order
        {
            Id = orderId,
            OrderReference = "O123",
            Type = OrderType.Delivery,
            State = OrderState.Confirmed,
            CustomerComments = "Ring the bell",
            Customer = new Customer
            {
                Id = customerId,
                FirstName = "Ada",
                LastName = "Lovelace",
                LoyaltyNumber = "LOYAL-1",
                DeliveryAddress = new Address
                {
                    Street = "Main Street",
                    StreetNumber = "42A",
                    ZipCode = "8000",
                    City = "Zurich",
                    Country = "CH"
                }
            },
            Items =
            [
                new OrderItem
                {
                    Id = itemId,
                    ProductId = productId,
                    Quantity = 2,
                    ItemPrice = 12.50m,
                    ProductDescription = "Burger",
                    CustomerComments = "No onions",
                    State = OrderItemState.AwaitingPreparation
                }
            ]
        };

        var roundTripped = entity.ToDto().ToEntity();

        Assert.Equal(orderId, roundTripped.Id);
        Assert.Equal("O123", roundTripped.OrderReference);
        Assert.Equal(OrderType.Delivery, roundTripped.Type);
        Assert.Equal(OrderState.Confirmed, roundTripped.State);
        Assert.Equal("Ring the bell", roundTripped.CustomerComments);
        Assert.Equal(customerId, roundTripped.Customer?.Id);
        Assert.Equal("LOYAL-1", roundTripped.Customer?.LoyaltyNumber);
        Assert.Equal("42A", roundTripped.Customer?.DeliveryAddress?.StreetNumber);
        var item = Assert.Single(roundTripped.Items!);
        Assert.Equal(itemId, item.Id);
        Assert.Equal(productId, item.ProductId);
        Assert.Equal("No onions", item.CustomerComments);
    }

    [Fact]
    public void ToFinanceDto_PreservesBillingFieldsAndPricingBreakdown()
    {
        var entity = new Order
        {
            Id = Guid.NewGuid(),
            Type = OrderType.Inhouse,
            State = OrderState.Paid,
            CustomerComments = "Company receipt",
            Customer = new Customer
            {
                InvoiceAddress = new Address { Street = "Market", StreetNumber = "7" }
            },
            Items = [new OrderItem { CustomerComments = "Extra sauce" }]
        };

        var dto = entity.ToFinanceDto(serviceFee: 2.40m, discount: 1.20m);

        Assert.Equal(2.40m, dto.ServiceFee);
        Assert.Equal(1.20m, dto.Discount);
        Assert.Equal("Company receipt", dto.CustomerComments);
        Assert.Equal("7", dto.Customer?.InvoiceAddress?.StreetNumber);
        Assert.Equal("Extra sauce", Assert.Single(dto.Items!).CustomerComments);
    }
}
