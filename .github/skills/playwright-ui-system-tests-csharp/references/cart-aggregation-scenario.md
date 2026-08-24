# Cart aggregation regression scenario

Use a fresh POS order and a single browser tab:

1. Add product A with quantity 1.
2. Add a different product B with quantity 1.
3. Add product A again in a separate action with quantity 2.
4. Read the cart through `ProductsPage`.
5. Assert exactly two cart lines.
6. Assert product A has aggregate quantity 3 and product B quantity 1.
7. Assert each line total equals `UnitPrice * Quantity`.
8. Assert the displayed cart total equals the sum of line totals.

The test method should call Page Object methods only. Product names may be used by the test for
readability because `ProductsPage` resolves them to stable product IDs.

When updating `AddProductAsync`, observe the target product's quantity or another deterministic
cart state before clicking, then wait for the expected post-click state. The method must work for
both a newly created cart line and an updated existing line. Fail with a useful timeout message;
do not silently return after an unobserved update.
