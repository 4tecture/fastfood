<template>
  <div id="app" class="flex h-screen">
    <router-view />
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style>
html, body {
  height: 100%;
}

#app {
  @reference font-sans, text-gray-800, h-full;
}
</style>