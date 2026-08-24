<template>
  <div
    class="flex justify-center items-center w-full min-h-full py-16"
    style="background: var(--ff-ground)"
    data-testid="order-confirmation-page">
    <div class="receipt">

      <!-- Header -->
      <div class="receipt-header">
        <h1 class="receipt-title" data-testid="order-confirmation-title">
          <span>{{ featureFlags.isEnabled('NewCheckoutExperience') ? 'Review order' : 'Order' }}</span>
          <strong v-if="order?.orderReference" data-testid="order-reference">
            {{ featureFlags.isEnabled('NewCheckoutExperience') ? order.orderReference : `#${order.orderReference}` }}
          </strong>
        </h1>
      </div>

      <!-- Empty state -->
      <p
        v-if="!order || order.items.length === 0"
        class="receipt-empty"
        data-testid="empty-order-message">
        Your order is empty.
      </p>

      <div v-else data-testid="order-details">

        <!-- Loyalty input -->
        <div
          v-if="featureFlags.isEnabled('LoyaltyProgram') && !isPaid"
          class="loyalty-block"
          data-testid="loyalty-program-section">
          <label
            class="loyalty-label"
            for="loyalty-input"
            data-testid="loyalty-label">
            Loyalty Member
          </label>
          <input
            id="loyalty-input"
            v-model="loyaltyNumber"
            type="text"
            placeholder="Enter loyalty number"
            class="loyalty-input"
            data-testid="loyalty-input"
            maxlength="20" />
          <p
            v-if="loyaltyNumber"
            class="loyalty-hint"
            data-testid="loyalty-discount-message">
            10% discount will be applied.
          </p>
        </div>

        <!-- Line items -->
        <div class="receipt-items">
          <div
            v-for="item in order.items"
            :key="item.id"
            class="receipt-line"
            :data-testid="`order-item-${item.productDescription.replace(/\s+/g, '-').toLowerCase()}`">
            <div class="receipt-line-left">
              <span class="receipt-line-qty" data-testid="item-quantity">{{ item.quantity }}</span>
              <span class="receipt-line-name" data-testid="item-name">{{ item.productDescription }}</span>
            </div>
            <span class="receipt-line-price" data-testid="item-total">
              {{ formatCurrency(item.quantity * item.itemPrice) }}
            </span>
          </div>
        </div>

        <!-- Pricing breakdown -->
        <div class="receipt-totals">
          <div class="receipt-total-row" data-testid="order-subtotal">
            <span class="receipt-total-label">Subtotal</span>
            <span class="receipt-total-value">{{ formatCurrency(subtotal) }}</span>
          </div>
          <div
            v-if="displayOrder.serviceFee"
            class="receipt-total-row receipt-total-surcharge"
            data-testid="service-fee">
            <span class="receipt-total-label">Peak Hour Service Fee</span>
            <span class="receipt-total-value">+ {{ formatCurrency(displayOrder.serviceFee) }}</span>
          </div>
          <div
            v-if="displayOrder.discount"
            class="receipt-total-row receipt-total-discount"
            data-testid="loyalty-discount">
            <span class="receipt-total-label">Loyalty Discount</span>
            <span class="receipt-total-value">− {{ formatCurrency(displayOrder.discount) }}</span>
          </div>
          <div class="receipt-total-row receipt-grand-total" data-testid="order-total">
            <span class="receipt-total-label">Total</span>
            <span class="receipt-total-value">{{ formatCurrency(totalOrderPrice) }}</span>
          </div>
        </div>

        <!-- Pay -->
        <button
          v-if="!isPaid"
          class="pay-btn"
          :class="{ 'pay-btn--new': featureFlags.isEnabled('NewCheckoutExperience') }"
          data-testid="pay-button"
          @click="pay">
          {{ featureFlags.isEnabled('NewCheckoutExperience') ? 'Complete Order' : 'Pay' }}
        </button>

        <!-- Post-payment -->
        <div v-else class="confirmed-block" data-testid="payment-confirmation">
          <div class="confirmed-rule" aria-hidden="true"></div>
          <p class="confirmed-msg" data-testid="payment-confirmed-message">
            Payment confirmed. Thank you — we'll have your order ready shortly.
          </p>
          <button
            class="confirmed-ok"
            data-testid="ok-button"
            @click="navigateToStart">
            Return to Start
          </button>
        </div>

      </div>
    </div>
  </div>
</template>

<script>
import { computed, watch, onBeforeUnmount, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useOrderStore } from '@/stores/orderStore';
import { useFeatureFlagsStore } from '@/stores/featureFlags';

export default {
  setup() {
    const router = useRouter();
    const orderStore = useOrderStore();
    const featureFlags = useFeatureFlagsStore();
    const order = computed(() => orderStore.currentOrder);
    const loyaltyNumber = ref('');

    const subtotal = computed(() => {
      if (!order.value?.items) return 0;
      return order.value.items.reduce((sum, item) => sum + (item.quantity * item.itemPrice), 0);
    });

    const clientSideDiscount = computed(() => {
      if (!loyaltyNumber.value || !featureFlags.isEnabled('LoyaltyProgram')) return 0;
      return Math.round(subtotal.value * 0.10 * 100) / 100;
    });

    const displayOrder = computed(() => {
      if (!order.value) return null;
      return { ...order.value, discount: clientSideDiscount.value || order.value.discount };
    });

    const totalOrderPrice = computed(() => {
      const base = subtotal.value;
      const serviceFee = order.value?.serviceFee || 0;
      const discount = clientSideDiscount.value || order.value?.discount || 0;
      return base + serviceFee - discount;
    });

    const isPaid = computed(() =>
      order.value && (order.value.state === 'Paid' || order.value.state === 'Processing')
    );

    let redirectTimer = null;

    watch(order, (newVal) => {
      if (newVal && (newVal.state === 'Paid' || newVal.state === 'Processing')) {
        clearTimeout(redirectTimer);
        redirectTimer = setTimeout(navigateToStart, 3000);
      }
    }, { deep: true });

    function pay() {
      orderStore.confirmPayment();
    }

    function navigateToStart() {
      clearTimeout(redirectTimer);
      redirectTimer = null;
      loyaltyNumber.value = '';
      featureFlags.startNewOrderSession();
      router.push('/');
    }

    onBeforeUnmount(() => clearTimeout(redirectTimer));

    function formatCurrency(value) {
      if (value === undefined || value === null) return '$0.00';
      return `$${value.toFixed(2)}`;
    }

    return {
      order,
      displayOrder,
      totalOrderPrice,
      subtotal,
      isPaid,
      loyaltyNumber,
      pay,
      navigateToStart,
      formatCurrency,
      featureFlags,
    };
  }
};
</script>

<style scoped>
/* ── Receipt card ─────────────────────────────────────────── */
.receipt {
  position: relative;
  overflow: hidden;
  width: 100%;
  max-width: 34rem;
  margin: 0 1.5rem;
  padding: 2.75rem;
  border-radius: 16px;
  background: var(--ff-ground-2);
  box-shadow: 0 14px 34px rgba(83, 45, 21, 0.14);
  box-sizing: border-box;
}

/* ── Header ───────────────────────────────────────────────── */
.receipt-header {
  margin-bottom: 2rem;
}

.receipt-title {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 1rem;
  margin: 0;
  color: var(--ff-ink);
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: -0.035em;
  line-height: 1.05;
}

.receipt-title strong {
  color: var(--ff-accent);
  font-size: 1.5rem;
  font-weight: 800;
  letter-spacing: -0.025em;
}

.receipt-empty {
  font-size: 1rem;
  font-weight: 600;
  color: var(--ff-ink-2);
  margin: 0;
}

/* ── Loyalty block ────────────────────────────────────────── */
.loyalty-block {
  margin-bottom: 1.5rem;
  padding-bottom: 1.5rem;
  border-bottom: 2px solid var(--ff-rule);
}

.loyalty-label {
  display: block;
  font-size: 0.9375rem;
  font-weight: 750;
  letter-spacing: 0;
  color: var(--ff-ink);
  margin-bottom: 0.5rem;
}

.loyalty-input {
  display: block;
  width: 100%;
  min-height: 50px;
  padding: 0.75rem 0.875rem;
  font-family: inherit;
  font-size: 0.9375rem;
  color: var(--ff-ink);
  background: var(--ff-ground);
  border: 2px solid var(--ff-rule);
  border-radius: 12px;
  outline: none;
  transition: border-color 0.15s ease;
  box-sizing: border-box;
}

.loyalty-input::placeholder {
  color: var(--ff-ink-2);
}

.loyalty-input:focus {
  border-color: var(--ff-accent);
  outline: 3px solid var(--ff-focus);
  outline-offset: 2px;
}

.loyalty-hint {
  margin: 0.5rem 0 0;
  font-size: 0.875rem;
  font-weight: 650;
  color: var(--ff-accent);
}

/* ── Line items ───────────────────────────────────────────── */
.receipt-items {
  margin-bottom: 0;
}

.receipt-line {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 0;
  border-bottom: 2px solid var(--ff-rule);
}

.receipt-line-left {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  min-width: 0;
  flex: 1;
}

.receipt-line-qty {
  font-size: 0.875rem;
  font-weight: 750;
  color: var(--ff-ink-2);
  flex-shrink: 0;
}

.receipt-line-name {
  font-size: 1rem;
  font-weight: 650;
  color: var(--ff-ink);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.receipt-line-price {
  font-size: 1rem;
  font-weight: 750;
  color: var(--ff-ink);
  white-space: nowrap;
  flex-shrink: 0;
}

/* ── Totals block ─────────────────────────────────────────── */
.receipt-totals {
  margin-top: 0;
  padding-top: 0;
  margin-bottom: 1.75rem;
}

.receipt-total-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  padding: 0.5rem 0;
  border-bottom: 2px solid var(--ff-rule);
}

.receipt-total-label {
  font-size: 0.9375rem;
  color: var(--ff-ink-2);
}

.receipt-total-value {
  font-size: 0.9375rem;
  font-weight: 700;
  color: var(--ff-ink);
}

.receipt-total-surcharge .receipt-total-value {
  color: var(--ff-ink);
}

.receipt-total-discount .receipt-total-value {
  color: var(--ff-accent);
}

.receipt-grand-total {
  border-top: 3px solid var(--ff-ink);
  border-bottom: none;
  padding-top: 0.75rem;
  margin-top: 0.125rem;
}

.receipt-grand-total .receipt-total-label {
  font-size: 1rem;
  font-weight: 800;
  letter-spacing: 0;
  text-transform: uppercase;
  color: var(--ff-ink);
}

.receipt-grand-total .receipt-total-value {
  font-size: 1.375rem;
  font-weight: 800;
  color: var(--ff-ink);
}

/* ── Pay button ───────────────────────────────────────────── */
.pay-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 58px;
  padding: 1rem 1.5rem;
  background: var(--ff-accent);
  color: var(--ff-btn-txt);
  font-family: inherit;
  font-size: 1rem;
  font-weight: 800;
  letter-spacing: 0;
  border: 2px solid var(--ff-accent);
  border-radius: 14px;
  box-shadow: 0 7px 16px rgba(87, 31, 17, 0.18);
  cursor: pointer;
  transition: background 0.15s ease, border-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}

.pay-btn:hover {
  background: var(--ff-accent-h);
  border-color: var(--ff-accent-h);
  box-shadow: 0 9px 20px rgba(87, 31, 17, 0.24);
  transform: translateY(-2px);
}

.pay-btn:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 4px;
}

.pay-btn:active {
  box-shadow: 0 4px 10px rgba(87, 31, 17, 0.2);
  transform: translateY(1px);
}

/* ── Confirmed state ──────────────────────────────────────── */
.confirmed-block {
  padding-top: 0.5rem;
}

.confirmed-rule {
  height: 1px;
  background: var(--ff-rule);
  margin-bottom: 1.25rem;
}

.confirmed-msg {
  font-size: 1rem;
  font-weight: 600;
  color: var(--ff-ink);
  line-height: 1.6;
  margin: 0 0 1.5rem;
}

.confirmed-ok {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 54px;
  padding: 0.875rem 1.5rem;
  background: transparent;
  border: 2px solid var(--ff-ink);
  border-radius: 14px;
  font-family: inherit;
  font-size: 0.9375rem;
  font-weight: 800;
  color: var(--ff-ink);
  cursor: pointer;
  transition: border-color 0.15s ease;
}

.confirmed-ok:hover {
  background: var(--ff-ink);
  color: var(--ff-ground);
}

.confirmed-ok:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 4px;
}

@media (max-width: 36rem) {
  .receipt {
    margin: 0 1rem;
    padding: 2rem 1.5rem;
  }

  .receipt-title {
    align-items: flex-start;
    flex-direction: column;
    gap: 0.4rem;
  }
}
</style>
