﻿namespace FinanceService.Common.Dtos;

public class CustomerDto
{
    public Guid Id { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public AddressDto? InvoiceAddress { get; set; }
    public AddressDto? DeliveryAddress { get; set; }
}