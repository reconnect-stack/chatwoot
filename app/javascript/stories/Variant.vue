<script setup>
import { computed, inject } from 'vue';

defineProps({
  title: { type: String, default: '' },
});

const layout = inject('storyLayout', null);

// Normalizes layout sizes: numbers and bare numeric strings -> px,
// everything else (e.g. '100%', '800px') passes through unchanged.
function normalizeSize(value) {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value === 'number') return `${value}px`;
  return /^\d+$/.test(value) ? `${value}px` : value;
}

const cellStyle = computed(() => {
  const current = layout?.value ?? {};
  return {
    width: normalizeSize(current.width),
    height: normalizeSize(current.height),
  };
});
</script>

<template>
  <section
    class="flex flex-col overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
    :style="cellStyle"
  >
    <div
      class="px-3 py-2 text-sm font-medium border-b text-n-slate-12 border-n-weak bg-n-alpha-1"
    >
      {{ title }}
    </div>
    <div class="flex-1 p-4 bg-n-background">
      <slot />
    </div>
  </section>
</template>
