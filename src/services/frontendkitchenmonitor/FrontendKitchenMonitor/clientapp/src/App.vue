<template>
  <div id="kitchen-app">
    <WorkMonitor/>
  </div>
</template>

<script>
import WorkMonitor from './components/WorkMonitor.vue';

export default {
  name: 'App',
  components: {
    WorkMonitor
  }
}
</script>

<style>
html,
body,
#app,
#kitchen-app {
  width: 100%;
  min-height: 100%;
  margin: 0;
}

body {
  background: var(--kw-ground);
  color: var(--kw-ink);
  font-family: 'Bricolage Grotesque', ui-sans-serif, system-ui, sans-serif;
}

*,
*::before,
*::after {
  box-sizing: border-box;
}

button {
  font: inherit;
  -webkit-tap-highlight-color: transparent;
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
