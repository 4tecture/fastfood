<template>
  <div class="flex w-full h-full overflow-hidden" data-testid="products-page">

    <!-- Scrollable product browsing area -->
    <div
      class="product-browser flex-1 overflow-y-auto"
      style="background: var(--ff-ground)"
      data-testid="products-list">
      <header class="menu-header">
        <div class="menu-brand" aria-label="FastFood">
          <span>Fast</span><strong>Food</strong>
        </div>
        <h1 class="menu-title">Menu</h1>
      </header>
      <div
        v-for="(products, category) in groupedProducts"
        :key="category"
        class="category-section"
        :data-testid="`category-${category}`">
        <div class="category-header">
          <h2 class="category-label">{{ category }}</h2>
        </div>

        <div
          v-for="product in products"
          :key="product.id"
          class="product-entry"
          :data-testid="`product-card-${product.id}`"
          :data-product-name="product.title">

          <!-- Text column -->
          <div class="product-info">
            <h3
              class="product-name"
              :data-testid="`product-name-${product.id}`">
              {{ product.title }}
            </h3>
            <p class="product-desc">{{ product.description }}</p>
            <div class="product-footer">
              <span class="product-price">{{ formatCurrency(product.price) }}</span>
              <div class="product-controls">
                <button
                  class="qty-btn"
                  :data-testid="`decrease-quantity-${product.id}`"
                  @click="decreaseQuantity(product)"
                  :aria-label="`Decrease quantity of ${product.title}`">
                  −
                </button>
                <span
                  class="qty-count"
                  :data-testid="`quantity-${product.id}`">
                  {{ product.quantity || 1 }}
                </span>
                <button
                  class="qty-btn"
                  :data-testid="`increase-quantity-${product.id}`"
                  @click="increaseQuantity(product)"
                  :aria-label="`Increase quantity of ${product.title}`">
                  +
                </button>
                <button
                  class="add-btn"
                  :data-testid="`add-to-cart-${product.id}`"
                  @click="addToCart(product)">
                  Add
                </button>
              </div>
            </div>
          </div>

          <!-- Image column -->
          <div class="product-img-wrap" aria-hidden="true">
            <img
              v-if="product.imageUrl"
              :src="product.imageUrl"
              :alt="product.title"
              class="product-img" />
            <!-- placeholder: replace with real product photography -->
            <div v-else class="product-img-placeholder"></div>
          </div>
        </div>
      </div>

      <!-- Bottom padding so last item isn't flush against the edge -->
      <div class="h-12" aria-hidden="true"></div>
    </div>

    <!-- Persistent cart sidebar -->
    <aside class="cart-sidebar">
      <ShoppingCart />
    </aside>
  </div>
</template>

<script>
import ShoppingCart from './ShoppingCart.vue';
import { useOrderStore } from '@/stores/orderStore';

export default {
  components: { ShoppingCart },
  setup() {
    const orderStore = useOrderStore();
    return { orderStore };
  },
  computed: {
    products() { return this.orderStore.products; },
    groupedProducts() {
      return this.products.reduce((acc, product) => {
        (acc[product.category] = acc[product.category] || []).push(product);
        return acc;
      }, {});
    },
  },
  methods: {
    increaseQuantity(product) {
      product.quantity = (product.quantity || 1) + 1;
    },
    decreaseQuantity(product) {
      if ((product.quantity || 1) > 1) product.quantity = product.quantity - 1;
    },
    async addToCart(product) {
      const qty = product.quantity || 1;
      const genId = () => (typeof crypto !== 'undefined' && crypto.randomUUID)
        ? crypto.randomUUID()
        : Math.random().toString(36).slice(2);
      const orderItem = {
        id: genId(),
        productId: product.id,
        quantity: qty,
        itemPrice: product.price ?? 0,
        productDescription: product.title,
      };
      await this.orderStore.addItemToOrder(orderItem);
      product.quantity = 1;
    },
    formatCurrency(value) {
      if (value === undefined || value === null) return '$0.00';
      return `$${value.toFixed(2)}`;
    },
  },
  created() {
    this.orderStore.fetchProducts();
  },
};
</script>

<style scoped>
/* ── Cart sidebar ─────────────────────────────────────────── */
.cart-sidebar {
  width: 360px;
  min-width: 360px;
  height: 100%;
  overflow-y: auto;
  background: var(--ff-cart-ground);
  padding: 2rem;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}

/* ── Menu header ──────────────────────────────────────────── */
.menu-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 2rem;
  padding: 2.25rem 3rem 1rem;
}

.menu-brand {
  display: inline-flex;
  align-items: baseline;
  color: var(--ff-ink);
  font-family: 'Paytone One', 'Bricolage Grotesque', sans-serif;
  font-size: 1.25rem;
  letter-spacing: -0.035em;
  line-height: 1;
}

.menu-brand strong {
  padding: 0.18rem 0.35rem 0.25rem 0.08rem;
  border-radius: 0.25rem;
  background: var(--ff-accent);
  color: #ffffff;
  font-weight: 400;
}

.menu-title {
  margin: 0;
  color: var(--ff-ink);
  font-size: clamp(2.25rem, 4vw, 3.5rem);
  font-weight: 800;
  letter-spacing: -0.035em;
  line-height: 0.95;
}

.category-section {
  padding: 0 3rem 1rem;
}

/* ── Category header ──────────────────────────────────────── */
.category-header {
  padding-top: 2rem;
  padding-bottom: 0.25rem;
}

.category-label {
  display: block;
  margin: 0;
  color: var(--ff-accent);
  font-size: 1.375rem;
  font-weight: 800;
  letter-spacing: -0.025em;
  line-height: 1.15;
}

/* ── Product entry row ────────────────────────────────────── */
.product-entry {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1.25rem 0;
  border-bottom: 2px solid var(--ff-rule);
}

/* ── Product text column ──────────────────────────────────── */
.product-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.product-name {
  font-size: 1.25rem;
  font-weight: 750;
  color: var(--ff-ink);
  margin: 0;
  line-height: 1.2;
  letter-spacing: -0.015em;
}

.product-desc {
  max-width: 65ch;
  font-size: 0.9375rem;
  color: var(--ff-ink-2);
  margin: 0;
  line-height: 1.45;
}

.product-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  margin-top: 0.65rem;
  flex-wrap: wrap;
}

.product-price {
  color: var(--ff-ink);
  font-size: 1.125rem;
  font-weight: 800;
  letter-spacing: -0.01em;
}

/* ── Quantity + Add controls ──────────────────────────────── */
.product-controls {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.qty-btn {
  width: 46px;
  height: 46px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--ff-ground-2);
  border: 2px solid transparent;
  border-radius: 12px;
  color: var(--ff-ink);
  font-size: 1.25rem;
  font-weight: 700;
  line-height: 1;
  cursor: pointer;
  transition: background 0.14s ease, border-color 0.14s ease, transform 0.14s ease;
  font-family: inherit;
}

.qty-btn:hover {
  border-color: var(--ff-accent);
}

.qty-btn:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 3px;
}

.qty-btn:active {
  transform: scale(0.96);
}

.qty-count {
  width: 2rem;
  text-align: center;
  font-size: 1rem;
  font-weight: 750;
  color: var(--ff-ink);
}

.add-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 46px;
  min-width: 5rem;
  padding: 0 1.25rem;
  background: var(--ff-accent);
  color: var(--ff-btn-txt);
  font-family: inherit;
  font-size: 0.9375rem;
  font-weight: 800;
  letter-spacing: 0;
  border: 2px solid var(--ff-accent);
  border-radius: 12px;
  cursor: pointer;
  transition: background 0.14s ease, border-color 0.14s ease, transform 0.14s ease;
  white-space: nowrap;
}

.add-btn:hover {
  background: var(--ff-accent-h);
  border-color: var(--ff-accent-h);
}

.add-btn:focus-visible {
  outline: 3px solid var(--ff-focus);
  outline-offset: 3px;
}

.add-btn:active {
  transform: scale(0.97);
}

/* ── Product image ────────────────────────────────────────── */
.product-img-wrap {
  flex-shrink: 0;
  width: 124px;
  height: 96px;
  border-radius: 14px;
  overflow: hidden;
  background: var(--ff-ground-2);
}

.product-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-img-placeholder {
  width: 100%;
  height: 100%;
  background: var(--ff-rule);
  opacity: 0.65;
}

@media (max-width: 62rem) {
  .cart-sidebar {
    width: 320px;
    min-width: 320px;
    padding: 1.5rem;
  }

  .menu-header,
  .category-section {
    padding-right: 2rem;
    padding-left: 2rem;
  }

  .product-entry {
    align-items: flex-start;
  }

  .product-img-wrap {
    width: 104px;
    height: 84px;
  }
}

@media (max-width: 48rem) {
  [data-testid='products-page'] {
    flex-direction: column;
    overflow: hidden;
  }

  .product-browser {
    flex: 1;
    overflow-y: auto;
    padding-bottom: 9rem;
  }

  .cart-sidebar {
    position: fixed;
    z-index: 10;
    right: 0;
    bottom: 0;
    left: 0;
    width: 100%;
    min-width: 0;
    height: auto;
    min-height: 0;
    max-height: 46vh;
    padding: 1.25rem 2rem;
    overflow-y: auto;
    box-shadow: 0 -10px 26px rgba(73, 49, 9, 0.16);
  }

  .menu-header {
    padding-top: 1.5rem;
  }

  .product-entry {
    display: grid;
    grid-template-columns: 1fr auto;
  }

  .product-img-wrap {
    grid-column: 2;
    grid-row: 1;
  }
}
</style>
