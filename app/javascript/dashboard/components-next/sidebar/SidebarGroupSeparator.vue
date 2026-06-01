<script setup>
import Icon from 'next/icon/Icon.vue';
import SidebarSortMenu from './SidebarSortMenu.vue';

defineProps({
  label: {
    type: String,
    default: '',
  },
  icon: {
    type: [Object, String],
    default: '',
  },
  sortOptions: {
    type: Array,
    default: () => [],
  },
  activeSort: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update-sort']);
</script>

<template>
  <div
    class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-8 text-n-slate-10 select-none"
  >
    <Icon v-if="icon" :icon="icon" class="size-4" />
    <span class="text-sm font-medium leading-5 flex-grow">
      {{ label }}
    </span>
    <SidebarSortMenu
      v-if="sortOptions.length"
      :active-sort="activeSort"
      :options="sortOptions"
      @update:sort="sortBy => emit('update-sort', sortBy)"
    />
  </div>
</template>
