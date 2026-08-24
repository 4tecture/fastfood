<template>
  <div id="order-status-app">
    <CustomerOrderStatus/>
  </div>
</template>

<script>
import CustomerOrderStatus from './components/CustomerOrderStatus.vue';

export default {
  name: 'App',
  components: {
    CustomerOrderStatus
  }
}
</script>

<style>
html,
body,
#app,
#order-status-app {
  width: 100%;
  height: 100%;
  margin: 0;
}

body {
  overflow: hidden;
  background: var(--ff-ground);
  color: var(--ff-ink);
  font-family: 'Bricolage Grotesque', ui-sans-serif, system-ui, sans-serif;
}

*,
*::before,
*::after {
  box-sizing: border-box;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
</style>
