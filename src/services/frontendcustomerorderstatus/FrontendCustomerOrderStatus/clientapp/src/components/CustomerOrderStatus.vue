<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useOrderStatusStore } from '@/stores/orderStatusStore';

const os = useOrderStatusStore();
const connectionState = ref('connecting');
const preparationPage = ref(0);
const readyPage = ref(0);
const pageSizes = ref({ preparing: 6, ready: 8 });
let rotationTimer;

const ordersInPreparation = computed(() => os.ordersInPreparation);
const ordersFinished = computed(() => os.ordersFinished);
const preparationPageCount = computed(() => Math.max(1, Math.ceil(ordersInPreparation.value.length / pageSizes.value.preparing)));
const readyPageCount = computed(() => Math.max(1, Math.ceil(ordersFinished.value.length / pageSizes.value.ready)));
const activePreparationPage = computed(() => preparationPage.value % preparationPageCount.value);
const activeReadyPage = computed(() => readyPage.value % readyPageCount.value);
const visiblePreparationOrders = computed(() => {
  const start = activePreparationPage.value * pageSizes.value.preparing;
  return ordersInPreparation.value.slice(start, start + pageSizes.value.preparing);
});
const visibleFinishedOrders = computed(() => {
  const start = activeReadyPage.value * pageSizes.value.ready;
  return ordersFinished.value.slice(start, start + pageSizes.value.ready);
});

function updatePageSizes() {
  if (window.innerWidth <= 520) pageSizes.value = { preparing: 2, ready: 2 };
  else if (window.innerWidth <= 800) pageSizes.value = { preparing: 4, ready: 4 };
  else pageSizes.value = { preparing: 6, ready: 8 };
}

onMounted(async () => {
  updatePageSizes();
  window.addEventListener('resize', updatePageSizes);
  rotationTimer = window.setInterval(() => {
    preparationPage.value += 1;
    readyPage.value += 1;
  }, 8000);

  try {
    await os.initializeSignalRHub({
      onStateChange: state => { connectionState.value = state; },
      onUpdateError: () => { connectionState.value = 'offline'; },
    });
  } catch (error) {
    console.error('Error connecting order status updates:', error);
    connectionState.value = 'offline';
  }
});

onUnmounted(() => {
  window.removeEventListener('resize', updatePageSizes);
  window.clearInterval(rotationTimer);
});
</script>

<template>
  <main class="status-screen" data-testid="customer-order-status">
    <header class="status-header">
      <div class="status-brand" aria-label="FastFood">
        <span>Fast</span><strong>Food</strong>
      </div>
      <h1 class="status-title">Order status</h1>
      <div class="live-status" :class="`live-status--${connectionState}`" role="status">
        <span class="live-dot" aria-hidden="true"></span>
        {{ connectionState === 'live' ? 'Live updates' : connectionState === 'offline' ? 'Updates offline' : 'Connecting' }}
      </div>
    </header>

    <div class="status-board">
      <section
        class="order-zone order-zone--preparing"
        aria-labelledby="preparation-title"
        data-testid="preparation-section">
        <div class="zone-heading">
          <h2 id="preparation-title" data-testid="preparation-title">Being made</h2>
          <span class="zone-meta">
            <span v-if="preparationPageCount > 1" class="page-position">
              Page {{ activePreparationPage + 1 }}/{{ preparationPageCount }}
            </span>
            <span class="zone-count" :aria-label="`${ordersInPreparation.length} orders being made`">{{ ordersInPreparation.length }}</span>
          </span>
        </div>
        <ul
          class="order-grid order-grid--preparing"
          aria-live="polite"
          data-testid="preparation-orders-list">
          <li
            v-for="order in visiblePreparationOrders"
            :key="order.id"
            class="order-token order-token--preparing"
            :aria-label="`Order ${order.orderReference} is being made`"
            :data-testid="`preparation-order-${order.orderReference.toLowerCase()}`">
            <span :data-testid="`preparation-order-text-${order.orderReference.toLowerCase()}`">{{ order.orderReference }}</span>
          </li>
        </ul>
        <p v-if="ordersInPreparation.length === 0" class="zone-empty">
          New orders will appear here.
        </p>
      </section>

      <section
        class="order-zone order-zone--ready"
        aria-labelledby="finished-title"
        data-testid="finished-section">
        <div class="zone-heading">
          <h2 id="finished-title" data-testid="finished-title">Ready for pickup</h2>
          <span class="zone-meta">
            <span v-if="readyPageCount > 1" class="page-position">
              Page {{ activeReadyPage + 1 }}/{{ readyPageCount }}
            </span>
            <span class="zone-count" :aria-label="`${ordersFinished.length} orders ready for pickup`">{{ ordersFinished.length }}</span>
          </span>
        </div>
        <ul
          class="order-grid order-grid--ready"
          aria-live="polite"
          data-testid="finished-orders-list">
          <li
            v-for="order in visibleFinishedOrders"
            :key="order.id"
            class="order-token order-token--ready"
            :aria-label="`Order ${order.orderReference} is ready for pickup`"
            :data-testid="`finished-order-${order.orderReference.toLowerCase()}`">
            <span :data-testid="`finished-order-text-${order.orderReference.toLowerCase()}`">{{ order.orderReference }}</span>
          </li>
        </ul>
        <p v-if="ordersFinished.length === 0" class="zone-empty zone-empty--ready">
          Ready orders will appear here.
        </p>
      </section>
    </div>
  </main>
</template>

<style scoped>
.status-screen {
  display: grid;
  grid-template-rows: auto minmax(0, 1fr);
  width: 100%;
  height: 100dvh;
  min-height: 36rem;
  background: var(--ff-ground);
}

.status-header {
  display: grid;
  grid-template-columns: minmax(10rem, 1fr) auto minmax(10rem, 1fr);
  align-items: center;
  gap: 2rem;
  min-height: 90px;
  padding: 1.1rem clamp(2rem, 4vw, 4.5rem);
  background: var(--ff-header);
  color: var(--ff-header-ink);
}

.status-brand {
  display: inline-flex;
  align-items: baseline;
  justify-self: start;
  font-family: 'Paytone One', 'Bricolage Grotesque', sans-serif;
  font-size: clamp(1.25rem, 2vw, 1.75rem);
  letter-spacing: -0.035em;
  line-height: 1;
}

.status-brand strong {
  padding: 0.2rem 0.42rem 0.28rem 0.08rem;
  border-radius: 0.28rem;
  background: var(--ff-accent);
  color: #ffffff;
  font-weight: 400;
}

.status-title {
  margin: 0;
  font-size: clamp(1.5rem, 2.4vw, 2.25rem);
  font-weight: 800;
  letter-spacing: -0.03em;
  line-height: 1;
}

.live-status {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  justify-self: end;
  color: #e8ddcf;
  font-size: 0.9375rem;
  font-weight: 700;
}

.live-dot {
  width: 0.75rem;
  height: 0.75rem;
  border: 3px solid var(--ff-highlight);
  border-radius: 50%;
}

.live-status--connecting {
  color: var(--ff-highlight);
}

.live-status--offline {
  color: #ff8f7a;
}

.status-board {
  display: grid;
  grid-template-columns: minmax(0, 42fr) minmax(0, 58fr);
  min-height: 0;
}

.order-zone {
  min-width: 0;
  overflow: hidden;
  padding: clamp(2rem, 4vw, 4rem);
}

.order-zone--preparing {
  background: var(--ff-ground);
}

.order-zone--ready {
  background: var(--ff-highlight);
}

.zone-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem;
  margin-bottom: clamp(2rem, 4vh, 3.5rem);
  padding-bottom: 1.25rem;
  border-bottom: 3px solid currentColor;
}

.zone-heading h2 {
  margin: 0;
  font-size: clamp(2rem, 4vw, 4rem);
  font-weight: 800;
  letter-spacing: -0.04em;
  line-height: 0.95;
}

.order-zone--preparing .zone-heading h2 {
  color: var(--ff-accent);
}

.zone-count {
  display: inline-flex;
  width: clamp(2.5rem, 4vw, 3.5rem);
  height: clamp(2.5rem, 4vw, 3.5rem);
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  background: var(--ff-ink);
  color: var(--ff-ground);
  font-size: clamp(1rem, 1.5vw, 1.375rem);
  font-weight: 800;
  font-variant-numeric: tabular-nums;
}

.zone-meta {
  display: inline-flex;
  flex: 0 0 auto;
  align-items: center;
  gap: 0.75rem;
}

.page-position {
  font-size: clamp(0.75rem, 1vw, 0.9375rem);
  font-weight: 800;
  white-space: nowrap;
}

ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
}

.order-grid {
  display: grid;
  align-content: start;
  gap: clamp(0.75rem, 1.5vw, 1.5rem);
}

.order-grid--preparing {
  grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr));
}

.order-grid--ready {
  grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr));
}

.order-token {
  display: flex;
  min-height: clamp(5rem, 12vh, 8rem);
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border-radius: 14px;
  font-size: clamp(2.25rem, 5vw, 5.5rem);
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.04em;
  line-height: 1;
  animation: token-arrive 420ms cubic-bezier(0.16, 1, 0.3, 1) both;
}

.order-token--preparing {
  background: var(--ff-ground-2);
  color: var(--ff-ink);
}

.order-token--ready {
  min-height: clamp(6.5rem, 15vh, 10rem);
  background: var(--ff-accent);
  color: #ffffff;
  box-shadow: 0 10px 24px rgba(111, 39, 15, 0.2);
}

.zone-empty {
  max-width: 24ch;
  margin: 0;
  color: var(--ff-ink-2);
  font-size: clamp(1.125rem, 1.8vw, 1.5rem);
  font-weight: 650;
  line-height: 1.4;
}

.zone-empty--ready {
  color: #5a4914;
}

@keyframes token-arrive {
  from {
    clip-path: inset(0 100% 0 0);
    transform: translateY(0.4rem);
  }
  to {
    clip-path: inset(0 0 0 0);
    transform: translateY(0);
  }
}

@media (max-width: 50rem) {
  .status-screen {
    height: 100%;
    min-height: 100dvh;
  }

  .status-header {
    grid-template-columns: 1fr auto;
    min-height: 76px;
    padding: 1rem 1.5rem;
  }

  .status-title {
    display: none;
  }

  .status-board {
    grid-template-columns: 1fr;
    overflow-y: auto;
  }

  .order-zone {
    min-height: 45vh;
    overflow: visible;
    padding: 2rem 1.5rem 2.5rem;
  }

  .zone-heading h2 {
    font-size: clamp(2.25rem, 9vw, 3.5rem);
  }
}
</style>
