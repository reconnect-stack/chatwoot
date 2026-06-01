<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  collapsible: {
    type: Boolean,
    default: false,
  },
  isExpanded: {
    type: Boolean,
    default: true,
  },
  label: {
    type: String,
    default: '',
  },
  icon: {
    type: [Object, String],
    default: '',
  },
  showTreeLine: {
    type: Boolean,
    default: false,
  },
  endTreeLine: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle']);
</script>

<template>
  <component
    :is="collapsible ? 'button' : 'div'"
    :type="collapsible ? 'button' : undefined"
    :aria-expanded="collapsible ? isExpanded : undefined"
    :title="label"
    class="relative flex items-center gap-2 px-2 py-1.5 rounded-lg h-8 text-n-slate-10 select-none min-w-0"
    :class="{
      'w-full': !collapsible,
      'pointer-events-none': !collapsible,
      'w-[calc(100%-1.25rem)] ltr:ml-5 rtl:mr-5 cursor-pointer hover:bg-n-alpha-2':
        collapsible,
      'child-item before:bg-n-slate-4 after:bg-transparent after:border-n-slate-4 before:left-0 rtl:before:right-0 ltr:!ml-3 rtl:!mr-3 ltr:!pl-4 rtl:!pr-4':
        showTreeLine,
      'tree-line-end': endTreeLine,
    }"
    @click.stop="emit('toggle')"
  >
    <Icon v-if="icon" :icon="icon" class="size-4" />
    <span
      class="text-sm font-medium leading-5 flex-grow truncate text-start"
      :class="{ 'ltr:pr-7 rtl:pl-7': collapsible }"
    >
      {{ label }}
    </span>
    <span
      v-if="collapsible"
      class="absolute top-1/2 -translate-y-1/2 size-3 flex-shrink-0 text-n-slate-10 ltr:right-4 rtl:left-4"
      :class="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
    />
  </component>
</template>
