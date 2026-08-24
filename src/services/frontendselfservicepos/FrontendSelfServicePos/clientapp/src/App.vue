<template>
  <div id="app" class="flex h-screen" data-testid="pos-app" :class="{ 'dark': isDarkMode }">
    <router-view />
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, computed } from 'vue';
import { useFeatureFlagsStore } from '@/stores/featureFlags';

const featureFlags = useFeatureFlagsStore();

const isDarkMode = computed(() => featureFlags.isEnabled('DarkMode'));

onMounted(() => {
  // Start polling for feature flag changes (fetches every 30 seconds)
  // This ensures runtime changes in Azure App Configuration are reflected
  featureFlags.startPolling();
});

onUnmounted(() => {
  // Clean up polling when app is destroyed
  featureFlags.stopPolling();
});
</script>

<style>
html, body {
  height: 100%;
  margin: 0;
  overscroll-behavior: none;
}

#app {
  font-family: 'Bricolage Grotesque', ui-sans-serif, system-ui, sans-serif;
  color: var(--ff-ink);
  background: var(--ff-ground);
  height: 100%;
}

button,
input {
  font: inherit;
}

button {
  -webkit-tap-highlight-color: transparent;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
</style>
