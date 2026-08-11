<template>
  <div data-testid="shopping-cart" class="cart-root">
    <h2 class="cart-heading" data-testid="shopping-cart-title">Your Order</h2>

    <!-- Empty state -->
    <p
      v-if="cart.length === 0"
      class="cart-empty"
      role="status"
      data-testid="empty-cart-message">
      Your picks will show up here.
    </p>

    <!-- Item list -->
    <div v-else class="cart-body" aria-live="polite" data-testid="cart-items-container">
      <div
        v-for="item in cart"
        :key="item.id"
        class="cart-item"
        :data-testid="`cart-item-${item.id}`"
        :data-product-id="item.productId"
        :data-product-name="item.productDescription">
        <div class="cart-item-left">
          <span class="cart-qty" :data-testid="`cart-item-text-${item.id}`">
            {{ item.quantity }}×
          </span>
          <span class="cart-item-name" :data-testid="`cart-item-name-${item.id}`">{{ item.productDescription }}</span>
        </div>
        <div class="cart-item-right">
          <span class="cart-item-price" :data-testid="`cart-item-price-${item.id}`">{{ formatCurrency(item.quantity * item.itemPrice) }}</span>
          <button
            class="cart-remove"
            :data-testid="`remove-item-${item.id}`"
            :aria-label="`Remove ${item.productDescription}`"
            @click="removeFromCart(item)">
            <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
              <path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" />
            </svg>
          </button>
        </div>
      </div>

      <!-- Total -->
      <div class="cart-total-row" data-testid="cart-total">
        <span class="cart-total-label">Total</span>
        <span class="cart-total-value" data-testid="cart-total-value">{{ formatCurrency(totalOrderPrice) }}</span>
      </div>

      <!-- Place order -->
      <button
        class="cart-order-btn"
        data-testid="order-button"
        @click="handleConfirmOrder">
        Place Order
      </button>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue';
import { storeToRefs } from 'pinia';
import { useOrderStore } from '@/stores/orderStore';

export default {
  setup() {
    const orderStore = useOrderStore();
    const { totalOrderPrice } = storeToRefs(orderStore);
    const cart = computed(() => orderStore.currentOrder?.items || []);
    return { orderStore, totalOrderPrice, cart };
  },
  methods: {
    async removeFromCart(item) {
      await this.orderStore.removeItemFromOrder(item);
    },
    async handleConfirmOrder() {
      await this.orderStore.confirmOrder();
      this.$router.push('/order-confirmation');
    },
    formatCurrency(value) {
      if (value === undefined || value === null) return '$0.00';
      return `$${value.toFixed(2)}`;
    },
  },
};
</script>

<style scoped>
.cart-root {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.cart-heading {
  margin: 0 0 1.5rem;
  color: var(--ff-cart-ink);
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: -0.035em;
  line-height: 1;
}

.cart-empty {
  max-width: 18ch;
  margin: 0;
  color: var(--ff-cart-muted);
  font-size: 1rem;
  font-weight: 600;
  line-height: 1.45;
}

.cart-body {
  display: flex;
  flex-direction: column;
  flex: 1;
}

/* ── Cart line item ───────────────────────────────────────── */
.cart-item {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 0.5rem;
  padding: 0.875rem 0;
  border-bottom: 1px solid var(--ff-cart-rule);
}

.cart-item-left {
  display: flex;
  align-items: baseline;
  gap: 0.375rem;
  min-width: 0;
  flex: 1;
}

.cart-qty {
  min-width: 1.5rem;
  color: var(--ff-cart-muted);
  font-size: 0.875rem;
  font-weight: 800;
  flex-shrink: 0;
}

.cart-item-name {
  color: var(--ff-cart-ink);
  font-size: 0.9375rem;
  font-weight: 650;
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.cart-item-right {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  flex-shrink: 0;
}

.cart-item-price {
  color: var(--ff-cart-ink);
  font-size: 0.9375rem;
  font-weight: 800;
  white-space: nowrap;
}

.cart-remove {
  width: 44px;
  min-width: 44px;
  height: 44px;
  min-height: 44px;
  padding: 0;
  background: transparent;
  border: 2px solid transparent;
  border-radius: 10px;
  cursor: pointer;
  color: var(--ff-cart-muted);
  line-height: 1;
  transition: background 0.14s ease, color 0.14s ease, transform 0.14s ease;
  font-family: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
}

.cart-remove:hover {
  background: rgba(32, 27, 24, 0.1);
  color: var(--ff-cart-ink);
}

.cart-remove:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 2px;
}

.cart-remove:active {
  transform: scale(0.95);
}

/* ── Total row ────────────────────────────────────────────── */
.cart-total-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  padding: 1.25rem 0 0;
  margin-top: 0.75rem;
  border-top: 3px solid var(--ff-cart-ink);
}

.cart-total-label {
  color: var(--ff-cart-ink);
  font-size: 1rem;
  font-weight: 800;
  letter-spacing: 0;
  text-transform: uppercase;
}

.cart-total-value {
  color: var(--ff-cart-ink);
  font-size: 1.375rem;
  font-weight: 800;
}

/* ── Place order button ───────────────────────────────────── */
.cart-order-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 58px;
  margin-top: 1.5rem;
  padding: 1rem 1.5rem;
  background: var(--ff-cart-cta);
  color: var(--ff-cart-cta-text);
  font-family: inherit;
  font-size: 1rem;
  font-weight: 800;
  letter-spacing: 0;
  border: 2px solid var(--ff-cart-cta);
  border-radius: 14px;
  box-shadow: 0 7px 16px rgba(56, 39, 12, 0.2);
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}

.cart-order-btn:hover {
  background: var(--ff-accent);
  border-color: var(--ff-accent);
  color: #ffffff;
  box-shadow: 0 9px 20px rgba(56, 39, 12, 0.26);
  transform: translateY(-2px);
}

.cart-order-btn:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 4px;
}

.cart-order-btn:active {
  box-shadow: 0 4px 10px rgba(56, 39, 12, 0.2);
  transform: translateY(1px);
}
</style>
