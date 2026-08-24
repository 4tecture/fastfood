using OrderService.Models.Entities;

namespace OrderPlacement.Workflows.Events;

public class AssignCustomerEvent
{
    public static string Name => nameof(AssignCustomerEvent);
    public Guid OrderId { get; set; }
    public required Customer Customer { get; set; }
}
