using Dapr.Actors.Runtime;
using OrderPlacement.Actors;
using OrderService.Models.Actors;

namespace OrderService.Actors.Unit.Tests;

public sealed class ActorContractTests
{
    [Fact]
    public void OrderActor_ImplementsTheRemoteAndReminderContracts()
    {
        Assert.True(typeof(IOrderActor).IsAssignableFrom(typeof(OrderActor)));
        Assert.True(typeof(IRemindable).IsAssignableFrom(typeof(OrderActor)));
    }
}
