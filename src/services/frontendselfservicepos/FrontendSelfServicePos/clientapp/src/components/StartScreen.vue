<template>
  <div
    class="start-screen"
    data-testid="welcome-screen">
    <div class="start-wrap">
      <div class="brand-lockup" aria-label="FastFood self service">
        <div class="brand-mark" aria-hidden="true">
          <span class="brand-mark-fast">FAST</span>
          <span class="brand-mark-food">FOOD</span>
        </div>
        <p class="brand-sub">Self service</p>
      </div>
      <button
        class="start-btn"
        data-testid="start-ordering-button"
        @click="startOrder">
        Start Ordering
      </button>
    </div>
  </div>
</template>

<script>
import { useOrderStore } from '@/stores/orderStore';
import { useFeatureFlagsStore } from '@/stores/featureFlags';
import { useRouter } from 'vue-router';

export default {
  setup() {
    const orderStore = useOrderStore();
    const featureFlags = useFeatureFlagsStore();
    const router = useRouter();

    async function startOrder() {
      featureFlags.startNewOrderSession();
      await orderStore.createOrder();
      router.push('/products');
    }
    return { startOrder };
  }
}
</script>

<style scoped>
.start-wrap {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: clamp(2.5rem, 7vh, 4.5rem);
}

.start-screen {
  position: relative;
  isolation: isolate;
  display: flex;
  width: 100%;
  height: 100%;
  min-height: 36rem;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: var(--ff-ground);
}

.start-screen::before,
.start-screen::after {
  position: absolute;
  z-index: -1;
  content: '';
  border-radius: 999px;
  pointer-events: none;
}

.start-screen::before {
  width: min(46vw, 40rem);
  aspect-ratio: 1;
  top: -24%;
  right: -10%;
  background: var(--ff-accent);
}

.start-screen::after {
  width: min(34vw, 28rem);
  aspect-ratio: 1;
  bottom: -22%;
  left: -8%;
  background: var(--ff-highlight);
}

.brand-lockup {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.brand-mark {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  color: var(--ff-ink);
  font-family: 'Paytone One', 'Bricolage Grotesque', sans-serif;
  font-size: clamp(4.5rem, 11vw, 6rem);
  font-weight: 400;
  letter-spacing: -0.04em;
  line-height: 0.72;
  transform: rotate(-3deg);
  animation: brand-arrive 540ms cubic-bezier(0.16, 1, 0.3, 1) both;
}

.brand-mark-fast {
  position: relative;
  z-index: 1;
  padding-left: 0.18em;
}

.brand-mark-food {
  position: relative;
  display: inline-block;
  padding: 0.1em 0.18em 0.16em 0.14em;
  color: #ffffff;
}

.brand-mark-food::before {
  position: absolute;
  z-index: -1;
  inset: 0.02em -0.03em -0.02em -0.02em;
  content: '';
  border-radius: 0.12em;
  background: var(--ff-accent);
  transform: skewX(-5deg);
}

.brand-sub {
  margin: 1.7rem 0 0;
  padding: 0.5rem 0.9rem;
  border-radius: 999px;
  background: var(--ff-highlight);
  color: var(--ff-highlight-ink);
  font-size: 0.875rem;
  font-weight: 800;
  letter-spacing: 0.09em;
  line-height: 1;
  text-transform: uppercase;
}

.start-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: min(20rem, calc(100vw - 3rem));
  min-height: 64px;
  padding: 1rem 2.75rem;
  background: var(--ff-accent);
  color: var(--ff-btn-txt);
  font-family: inherit;
  font-size: 1.125rem;
  font-weight: 800;
  letter-spacing: 0;
  border: 2px solid var(--ff-accent);
  border-radius: 14px;
  box-shadow: 0 8px 18px rgba(87, 31, 17, 0.18);
  cursor: pointer;
  transition: background 0.16s ease, border-color 0.16s ease, transform 0.16s ease, box-shadow 0.16s ease;
}

.start-btn:hover {
  background: var(--ff-accent-h);
  border-color: var(--ff-accent-h);
  box-shadow: 0 10px 22px rgba(87, 31, 17, 0.24);
  transform: translateY(-2px);
}

.start-btn:active {
  box-shadow: 0 4px 10px rgba(87, 31, 17, 0.2);
  transform: translateY(1px);
}

.start-btn:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 4px;
}

@keyframes brand-arrive {
  from {
    clip-path: inset(0 100% 0 0);
    transform: rotate(-3deg) translateY(0.25rem);
  }
  to {
    clip-path: inset(0 0 0 0);
    transform: rotate(-3deg) translateY(0);
  }
}

@media (max-width: 40rem) {
  .start-screen::before {
    top: -12%;
    right: -28%;
  }

  .start-screen::after {
    bottom: -10%;
    left: -20%;
  }
}
</style>
