using Microsoft.Playwright;
using System.Globalization;
using System.Text.RegularExpressions;

namespace FastFood.Ui.System.Tests.PageObjects.SelfServicePos;

/// <summary>
/// Page object for the Self Service POS Order Confirmation page
/// URL: /order-confirmation
/// 
/// BEST PRACTICE: This page object hides UI automation complexity from testers.
/// Shows order number, items, and payment options.
/// The PayForOrder() method handles payment and returns the next page object in the workflow.
/// </summary>
public class OrderConfirmationPage : BasePage
{
    public OrderConfirmationPage(IPage page, string baseUrl) : base(page, baseUrl)
    {
    }

    public override async Task NavigateAsync()
    {
        await Page.GotoAsync($"{BaseUrl}order-confirmation");
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
    }

    /// <summary>
    /// Gets the order number from the confirmation page.
    /// Useful for tracking the order through subsequent steps.
    /// </summary>
    /// <returns>Order number (e.g., "O12345") or null if not found</returns>
    public async Task<string?> GetOrderNumberAsync()
    {
        var reference = await Page.GetByTestId("order-reference").TextContentAsync() ?? "";
        var match = Regex.Match(reference, @"O\d+", RegexOptions.IgnoreCase);
        return match.Success ? match.Value.ToUpperInvariant() : null;
    }

    public async Task<string> GetHeadingTextAsync()
    {
        return (await Page.GetByTestId("order-confirmation-title").TextContentAsync() ?? "").Trim();
    }

    public async Task<string> GetPayButtonTextAsync()
    {
        return (await Page.GetByTestId("pay-button").TextContentAsync() ?? "").Trim();
    }

    public async Task<bool> IsLoyaltyProgramVisibleAsync()
    {
        return await Page.GetByTestId("loyalty-program-section").IsVisibleAsync();
    }

    public async Task EnterLoyaltyNumberAsync(string loyaltyNumber)
    {
        await Page.GetByTestId("loyalty-input").FillAsync(loyaltyNumber);
        await Page.GetByTestId("loyalty-discount-message").WaitForAsync(new() { State = WaitForSelectorState.Visible });
    }

    public async Task<decimal> GetSubtotalAsync()
    {
        return ParseCurrency(await Page.GetByTestId("order-subtotal").TextContentAsync() ?? "");
    }

    public async Task<decimal> GetLoyaltyDiscountAsync()
    {
        return ParseCurrency(await Page.GetByTestId("loyalty-discount").TextContentAsync() ?? "");
    }

    /// <summary>
    /// Gets the list of items in the order for verification.
    /// </summary>
    /// <returns>List of order items with quantity, name, and price</returns>
    public async Task<List<OrderItem>> GetOrderItemsAsync()
    {
        var items = new List<OrderItem>();
        
        // Find all order items using test IDs
        var itemLocators = Page.Locator("[data-testid^='order-item-']");
        var count = await itemLocators.CountAsync();

        for (int i = 0; i < count; i++)
        {
            var item = itemLocators.Nth(i);
            
            var quantityText = await item.GetByTestId("item-quantity").TextContentAsync() ?? "0";
            var productName = await item.GetByTestId("item-name").TextContentAsync() ?? "";
            var priceText = await item.GetByTestId("item-total").TextContentAsync() ?? "$0";

            items.Add(new OrderItem
            {
                Quantity = int.Parse(quantityText.Trim()),
                ProductName = productName.Trim(),
                Price = decimal.Parse(priceText.Replace("$", "").Trim())
            });
        }

        return items;
    }

    /// <summary>
    /// Gets the total amount for the order.
    /// </summary>
    /// <returns>Total price as decimal</returns>
    public async Task<decimal> GetTotalAsync()
    {
        var totalText = await Page.GetByTestId("order-total").TextContentAsync() ?? "";
        return ParseCurrency(totalText);
    }

    /// <summary>
    /// Proceeds with payment by clicking the Pay button.
    /// Waits for payment processing to complete and returns a PaymentConfirmationPage object.
    /// </summary>
    /// <returns>PaymentConfirmationPage object showing payment success</returns>
    public async Task<PaymentConfirmationPage> PayForOrderAsync()
    {
        await Page.GetByTestId("pay-button").ClickAsync();
        
        // SPA: No navigation, wait for payment to process and confirmation to appear
        await Page.GetByTestId("payment-confirmation").WaitForAsync(new() { State = WaitForSelectorState.Visible, Timeout = 15000 });
        
        return new PaymentConfirmationPage(Page, BaseUrl);
    }

    private static decimal ParseCurrency(string value)
    {
        var match = Regex.Match(value, @"\$\s*([0-9]+(?:\.[0-9]+)?)");
        return match.Success
            ? decimal.Parse(match.Groups[1].Value, CultureInfo.InvariantCulture)
            : 0;
    }
}

public class OrderItem
{
    public int Quantity { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Price { get; set; }
}
