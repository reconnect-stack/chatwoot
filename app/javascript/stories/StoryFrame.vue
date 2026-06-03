<script setup>
import { ref, onErrorCaptured } from 'vue';

// Per-story error boundary. Keyed by the story path in App.vue, so it remounts
// (and resets) on navigation. Containing the error here keeps one broken story
// from tearing down the whole harness, mirroring Histoire's per-story isolation.
defineProps({
  component: { type: [Object, Function], default: null },
});

const error = ref(null);
onErrorCaptured(err => {
  error.value = err;
  return false;
});
</script>

<template>
  <div v-if="error" class="flex flex-col h-full gap-3 p-6 overflow-auto">
    <p class="text-sm font-semibold text-n-ruby-11">
      This story failed to render.
    </p>
    <div
      class="p-3 font-mono text-xs whitespace-pre-wrap rounded-md text-n-slate-11 bg-n-alpha-1"
    >
      {{ error.stack || error.message }}
    </div>
  </div>
  <component :is="component" v-else />
</template>
