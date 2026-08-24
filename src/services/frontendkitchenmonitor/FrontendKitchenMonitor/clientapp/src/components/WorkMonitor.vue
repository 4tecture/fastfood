<script setup>
import { computed, onMounted, ref } from 'vue'
import { useKitchenStore } from '@/stores/kitchenStore'

const ks = useKitchenStore()
const isLoading = ref(true)
const loadError = ref('')
const actionError = ref('')
const connectionState = ref('connecting')
const busyItemIds = ref(new Set())
const completionAnnouncement = ref('')

onMounted(async () => {
  try {
    await ks.fetchPendingOrders()
  } catch (error) {
    console.error('Error loading kitchen orders:', error)
    loadError.value = 'Orders could not be loaded. Refresh the screen to try again.'
  }

  try {
    await ks.initializeSignalRHub({
      onStateChange: state => {
        connectionState.value = state
        if (state === 'live') {
          loadError.value = ''
          if (actionError.value.startsWith('Live updates paused')) actionError.value = ''
        }
      },
      onUpdateError: () => {
        actionError.value = 'Live updates paused. The monitor is reconnecting automatically.'
      },
    })
  } catch (error) {
    console.error('Error connecting kitchen updates:', error)
    connectionState.value = 'offline'
  } finally {
    isLoading.value = false
  }
})

// Presentational projection with unfinished items first and completed work last.
const pendingOrders = computed(() => ks.pendingOrders.map(order => {
  const orderItems = (order.items?.map(item => ({
    id: item.id,
    name: item.productDescription,
    state: item.state,
  })) ?? [])
    .slice()
    .sort((a, b) => {
      const aFinished = a.state === 'Finished'
      const bFinished = b.state === 'Finished'
      if (aFinished === bFinished) return 0
      return aFinished ? 1 : -1
    })

  const completedCount = orderItems.filter(item => item.state === 'Finished').length

  return {
    id: order.id,
    name: order.orderReference,
    orderItems,
    completedCount,
    remainingCount: orderItems.length - completedCount,
  }
}))

const openItemCount = computed(() => pendingOrders.value.reduce(
  (total, order) => total + order.remainingCount,
  0,
))

function isFinishing(itemId) {
  return busyItemIds.value.has(itemId)
}

async function finishOrderItem(item, orderName) {
  if (isFinishing(item.id)) return

  actionError.value = ''
  completionAnnouncement.value = ''
  busyItemIds.value = new Set([...busyItemIds.value, item.id])

  try {
    await ks.finishOrderItem(item.id)
    await ks.fetchPendingOrders()
    completionAnnouncement.value = `${item.name} for order ${orderName} marked done.`
  } catch (error) {
    console.error('Error finishing kitchen item:', error)
    actionError.value = 'That item was not updated. Check the connection and try again.'
  } finally {
    const nextBusyItems = new Set(busyItemIds.value)
    nextBusyItems.delete(item.id)
    busyItemIds.value = nextBusyItems
  }
}
</script>

<template>
  <main class="kitchen-monitor" data-testid="kitchen-monitor">
    <p class="sr-only" role="status" aria-live="polite">{{ completionAnnouncement }}</p>
    <header class="command-bar">
      <div class="command-brand" aria-label="FastFood">
        <span>Fast</span><strong>Food</strong>
      </div>

      <h1 data-testid="kitchen-title">Kitchen Work Monitor</h1>

      <div class="command-summary" aria-live="polite">
        <div class="work-count">
          <strong>{{ pendingOrders.length }}</strong>
          <span>{{ pendingOrders.length === 1 ? 'order' : 'orders' }}</span>
        </div>
        <div class="work-count">
          <strong>{{ openItemCount }}</strong>
          <span>items open</span>
        </div>
        <div class="connection-state" :class="`connection-state--${connectionState}`" role="status">
          <span aria-hidden="true"></span>
          {{ connectionState === 'live' ? 'Live' : connectionState === 'offline' ? 'Offline' : 'Connecting' }}
        </div>
      </div>
    </header>

    <div v-if="actionError" class="error-banner" role="alert">
      <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true">
        <path d="M12 3L2.8 20h18.4L12 3Z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" />
        <path d="M12 9v5M12 17.5v.2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
      </svg>
      <span>{{ actionError }}</span>
    </div>

    <section class="work-surface" aria-label="Active kitchen orders">
      <div v-if="isLoading" class="system-state" role="status">
        <span class="loading-mark" aria-hidden="true"></span>
        <h2>Loading kitchen orders</h2>
        <p>Connecting to the live work queue.</p>
      </div>

      <div v-else-if="loadError" class="system-state system-state--error" role="alert">
        <h2>Kitchen queue unavailable</h2>
        <p>{{ loadError }}</p>
      </div>

      <div v-else-if="pendingOrders.length === 0" class="system-state" role="status">
        <svg viewBox="0 0 48 48" width="52" height="52" aria-hidden="true">
          <path d="M8 14h32M12 14v23h24V14M18 9h12v5M18 22h12M18 29h8" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        <h2>Kitchen queue is clear</h2>
        <p>New paid orders will appear here automatically.</p>
      </div>

      <div v-else class="workboard" data-testid="orders-container">
        <article
          v-for="order in pendingOrders"
          :key="order.id"
          class="order-ticket"
          :data-testid="`order-card-${order.name.toLowerCase()}`">
          <header class="ticket-header">
            <div>
              <h2 :data-testid="`order-title-${order.name.toLowerCase()}`">{{ order.name }}</h2>
              <p>{{ order.remainingCount }} {{ order.remainingCount === 1 ? 'item' : 'items' }} remaining</p>
            </div>
            <div class="ticket-progress" :aria-label="`${order.completedCount} of ${order.orderItems.length} items finished`">
              <strong>{{ order.completedCount }}/{{ order.orderItems.length }}</strong>
              <span>done</span>
            </div>
          </header>

          <ul :data-testid="`order-items-${order.name.toLowerCase()}`">
            <li
              v-for="item in order.orderItems"
              :key="item.id"
              class="order-item"
              :class="{ 'order-item--finished': item.state === 'Finished' }"
              :data-testid="`order-item-${item.id}`"
              :data-order-ref="order.name.toLowerCase()"
              :data-product-name="item.name">
              <span class="item-name" :data-testid="`item-name-${item.id}`">{{ item.name }}</span>

              <span
                v-if="item.state === 'Finished'"
                class="done-status"
                :data-testid="`item-finished-${item.id}`">
                <svg viewBox="0 0 24 24" width="19" height="19" aria-hidden="true">
                  <path d="m5 12.5 4.2 4.2L19 7" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
                Done
              </span>
              <button
                v-else
                class="finish-button"
                type="button"
                :disabled="isFinishing(item.id)"
                :aria-busy="isFinishing(item.id)"
                :aria-label="`Finish ${item.name} for order ${order.name}`"
                :data-testid="`finish-button-${item.id}`"
                @click="finishOrderItem(item, order.name)">
                <svg v-if="!isFinishing(item.id)" viewBox="0 0 24 24" width="19" height="19" aria-hidden="true">
                  <path d="m5 12.5 4.2 4.2L19 7" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
                {{ isFinishing(item.id) ? 'Finishing…' : 'Finish' }}
              </button>
            </li>
          </ul>
        </article>
      </div>
    </section>
  </main>
</template>

<style scoped>
.kitchen-monitor {
  min-height: 100dvh;
  background: var(--kw-ground);
  color: var(--kw-ink);
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.command-bar {
  position: sticky;
  z-index: 10;
  top: 0;
  display: grid;
  grid-template-columns: auto minmax(14rem, 1fr) auto;
  align-items: center;
  gap: clamp(1.5rem, 3vw, 3.5rem);
  min-height: 88px;
  padding: 1rem clamp(1.25rem, 3vw, 3rem);
  border-bottom: 1px solid var(--kw-rule);
  background: #12100e;
}

.command-brand {
  display: inline-flex;
  align-items: baseline;
  font-family: 'Paytone One', 'Bricolage Grotesque', sans-serif;
  font-size: 1.25rem;
  letter-spacing: -0.035em;
  line-height: 1;
}

.command-brand strong {
  padding: 0.18rem 0.35rem 0.25rem 0.08rem;
  border-radius: 0.25rem;
  background: var(--kw-accent);
  color: #ffffff;
  font-weight: 400;
}

.command-bar h1 {
  margin: 0;
  font-size: clamp(1.35rem, 2.2vw, 2rem);
  font-weight: 800;
  letter-spacing: -0.03em;
  line-height: 1;
}

.command-summary {
  display: flex;
  align-items: center;
  gap: 1.25rem;
}

.work-count {
  display: flex;
  align-items: baseline;
  gap: 0.4rem;
  white-space: nowrap;
}

.work-count strong {
  color: var(--kw-highlight);
  font-size: 1.375rem;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
}

.work-count span,
.connection-state {
  color: var(--kw-muted);
  font-size: 0.8125rem;
  font-weight: 700;
}

.connection-state {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
}

.connection-state > span {
  width: 0.65rem;
  height: 0.65rem;
  border: 2px solid currentColor;
  border-radius: 50%;
}

.connection-state--live {
  color: var(--kw-done);
}

.connection-state--connecting {
  color: var(--kw-highlight);
}

.connection-state--offline {
  color: var(--kw-error);
}

.error-banner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem clamp(1.25rem, 3vw, 3rem);
  background: #4a211b;
  color: #ffe6df;
  font-size: 0.9375rem;
  font-weight: 700;
}

.error-banner svg {
  flex: 0 0 auto;
}

.work-surface {
  padding: clamp(1.25rem, 2.5vw, 2.5rem);
}

.workboard {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 28rem), 1fr));
  align-items: start;
  gap: clamp(1rem, 2vw, 1.75rem);
}

.order-ticket {
  overflow: hidden;
  border: 1px solid var(--kw-rule);
  border-radius: 14px;
  background: var(--kw-panel);
}

.ticket-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.25rem 1.35rem;
  background: var(--kw-panel-2);
}

.ticket-header h2 {
  margin: 0;
  color: var(--kw-ink);
  font-size: 2rem;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.035em;
  line-height: 1;
}

.ticket-header p {
  margin: 0.45rem 0 0;
  color: var(--kw-muted);
  font-size: 0.875rem;
  font-weight: 650;
}

.ticket-progress {
  display: flex;
  min-width: 4.5rem;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.65rem 0.8rem;
  border-radius: 12px;
  background: var(--kw-highlight);
  color: var(--kw-highlight-ink);
}

.ticket-progress strong {
  font-size: 1.125rem;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  line-height: 1;
}

.ticket-progress span {
  margin-top: 0.15rem;
  font-size: 0.6875rem;
  font-weight: 800;
  text-transform: uppercase;
}

.order-ticket ul {
  margin: 0;
  padding: 0;
  list-style: none;
}

.order-item {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 0.85rem;
  min-height: 72px;
  padding: 0.75rem 1rem 0.75rem 1.35rem;
  border-top: 1px solid var(--kw-rule);
}

.order-item:first-child {
  border-top: none;
}

.order-item--finished {
  background: rgba(159, 205, 133, 0.06);
}

.item-name {
  overflow: hidden;
  color: var(--kw-ink);
  font-size: 1rem;
  font-weight: 700;
  line-height: 1.3;
  text-overflow: ellipsis;
}

.order-item--finished .item-name {
  color: var(--kw-muted);
  text-decoration: line-through;
  text-decoration-thickness: 2px;
}

.finish-button,
.done-status {
  display: inline-flex;
  min-width: 6.25rem;
  min-height: 48px;
  align-items: center;
  justify-content: center;
  gap: 0.45rem;
  border-radius: 12px;
  font-size: 0.9375rem;
  font-weight: 800;
}

.finish-button {
  padding: 0.7rem 1rem;
  border: 2px solid var(--kw-accent);
  background: var(--kw-accent);
  color: #20120e;
  cursor: pointer;
  transition: background 0.14s ease, border-color 0.14s ease, transform 0.14s ease;
}

.finish-button:hover:not(:disabled) {
  border-color: var(--kw-accent-hover);
  background: var(--kw-accent-hover);
  transform: translateY(-1px);
}

.finish-button:active:not(:disabled) {
  transform: translateY(1px);
}

.finish-button:focus-visible {
  outline: 3px solid var(--kw-focus);
  outline-offset: 3px;
}

.finish-button:disabled {
  cursor: wait;
  opacity: 0.72;
}

.done-status {
  color: var(--kw-done);
  animation: done-reveal 360ms cubic-bezier(0.16, 1, 0.3, 1) both;
}

.system-state {
  display: flex;
  min-height: calc(100dvh - 10rem);
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 1.5rem;
  color: var(--kw-muted);
  text-align: center;
}

.system-state svg {
  margin-bottom: 1.25rem;
  color: var(--kw-highlight);
}

.system-state h2 {
  margin: 0;
  color: var(--kw-ink);
  font-size: clamp(1.75rem, 4vw, 3rem);
  font-weight: 800;
  letter-spacing: -0.035em;
}

.system-state p {
  max-width: 38ch;
  margin: 0.75rem 0 0;
  font-size: 1rem;
  line-height: 1.5;
}

.system-state--error h2,
.system-state--error {
  color: var(--kw-error);
}

.loading-mark {
  width: 2.5rem;
  height: 2.5rem;
  margin-bottom: 1.25rem;
  border: 5px solid var(--kw-rule);
  border-top-color: var(--kw-highlight);
  border-radius: 50%;
  animation: loading-spin 700ms linear infinite;
}

@keyframes loading-spin {
  to { transform: rotate(360deg); }
}

@keyframes done-reveal {
  from { clip-path: inset(0 100% 0 0); }
  to { clip-path: inset(0 0 0 0); }
}

@media (max-width: 64rem) {
  .command-bar {
    grid-template-columns: auto 1fr;
  }

  .command-bar h1 {
    display: none;
  }
}

@media (max-width: 42rem) {
  .command-bar {
    align-items: center;
    padding: 1rem;
  }

  .command-summary {
    justify-content: flex-end;
    gap: 0.65rem;
  }

  .work-surface {
    padding: 1rem;
  }

  .order-item {
    grid-template-columns: auto minmax(0, 1fr);
    padding: 0.875rem 1rem;
  }

  .finish-button,
  .done-status {
    grid-column: 1 / -1;
    width: 100%;
  }
}
</style>
