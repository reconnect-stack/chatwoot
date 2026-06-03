<script setup>
import { computed, provide } from 'vue';

const props = defineProps({
  title: { type: String, required: true },
  layout: {
    type: Object,
    default: () => ({ type: 'grid', width: '80%' }),
  },
  // Accepted for API compatibility with Histoire; not used by the harness.
  group: { type: String, default: '' },
});

const layout = computed(() => ({ type: 'grid', ...props.layout }));
provide('storyLayout', layout);

const name = computed(() => props.title.split('/').pop());
const containerClass = computed(() =>
  layout.value.type === 'single'
    ? 'flex flex-col gap-6'
    : 'flex flex-wrap items-start gap-6'
);
</script>

<template>
  <div class="flex flex-col h-full min-h-0 bg-n-background">
    <header
      class="flex flex-col gap-0.5 px-6 py-4 border-b border-n-weak shrink-0"
    >
      <h1 class="text-lg font-semibold text-n-slate-12">{{ name }}</h1>
      <p class="text-xs text-n-slate-10">{{ title }}</p>
    </header>
    <div class="flex-1 min-h-0 overflow-auto p-6">
      <div :class="containerClass">
        <slot />
      </div>
    </div>
  </div>
</template>
