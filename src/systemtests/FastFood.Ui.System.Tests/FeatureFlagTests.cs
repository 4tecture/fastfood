using FastFood.Ui.System.Tests.Base;
using FastFood.Ui.System.Tests.Helpers;

namespace FastFood.Ui.System.Tests;

/// <summary>
/// Verifies the user-visible POS variants controlled by frontend feature flags.
/// The flag endpoint is intercepted per browser page so the tests are deterministic
/// and do not depend on the current rollout configuration.
/// </summary>
public class FeatureFlagTests : PlaywrightTestBase
{
    [Fact]
    public async Task DarkMode_ShouldFollowFeatureFlag()
    {
        var lightWelcomePage = await BrowserHelper.OpenSelfServicePosAsync(
            Context,
            Configuration,
            Flags(darkMode: false));
        Assert.False(await lightWelcomePage.IsDarkModeEnabledAsync());

        var darkWelcomePage = await BrowserHelper.OpenSelfServicePosAsync(
            Context,
            Configuration,
            Flags(darkMode: true));
        Assert.True(await darkWelcomePage.IsDarkModeEnabledAsync());
    }

    [Fact]
    public async Task NewCheckoutExperience_ShouldUseAlternateCheckoutCopy()
    {
        var welcomePage = await BrowserHelper.OpenSelfServicePosAsync(
            Context,
            Configuration,
            Flags(newCheckoutExperience: true));

        var productsPage = await welcomePage.StartOrderingAsync();
        await productsPage.AddProductAsync("Cheeseburger");
        var confirmationPage = await productsPage.CheckoutAsync();

        Assert.Contains("Review order", await confirmationPage.GetHeadingTextAsync());
        Assert.Equal("Complete Order", await confirmationPage.GetPayButtonTextAsync());
        Assert.NotNull(await confirmationPage.GetOrderNumberAsync());
    }

    [Fact]
    public async Task LoyaltyProgram_ShouldApplyTenPercentDiscount()
    {
        var welcomePage = await BrowserHelper.OpenSelfServicePosAsync(
            Context,
            Configuration,
            Flags(loyaltyProgram: true));

        var productsPage = await welcomePage.StartOrderingAsync();
        await productsPage.AddProductAsync("Cheeseburger");
        var confirmationPage = await productsPage.CheckoutAsync();

        Assert.True(await confirmationPage.IsLoyaltyProgramVisibleAsync());
        var totalBeforeDiscount = await confirmationPage.GetTotalAsync();
        var subtotal = await confirmationPage.GetSubtotalAsync();

        await confirmationPage.EnterLoyaltyNumberAsync("DEMO-LOYALTY-123");

        var expectedDiscount = Math.Round(subtotal * 0.10m, 2);
        Assert.Equal(expectedDiscount, await confirmationPage.GetLoyaltyDiscountAsync());
        Assert.Equal(totalBeforeDiscount - expectedDiscount, await confirmationPage.GetTotalAsync());
    }

    private static IReadOnlyDictionary<string, bool> Flags(
        bool loyaltyProgram = false,
        bool newCheckoutExperience = false,
        bool darkMode = false)
    {
        return new Dictionary<string, bool>
        {
            ["LoyaltyProgram"] = loyaltyProgram,
            ["NewCheckoutExperience"] = newCheckoutExperience,
            ["DarkMode"] = darkMode
        };
    }
}
