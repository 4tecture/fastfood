using OrderService.Models.Entities;

namespace OrderPlacement.Workflows.Events;

public class AssignInvoiceAddressEvent
{
    public static string Name => nameof(AssignInvoiceAddressEvent);
    public Guid OrderId { get; set; }
    public required Address Address { get; set; }
}
