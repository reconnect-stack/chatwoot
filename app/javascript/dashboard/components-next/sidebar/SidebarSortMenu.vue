<script setup>
import { computed, nextTick, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import Button from 'dashboard/components-next/button/Button.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { SIDEBAR_SORT_KEYS } from 'dashboard/helper/sidebarSort';

const props = defineProps({
  activeSort: {
    type: String,
    default: '',
  },
  options: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:sort']);

const { t } = useI18n();
const [isOpen, toggleOpen] = useToggle(false);
const triggerRef = ref(null);
const popoverRef = ref(null);

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  popoverRef,
  isOpen,
  { align: 'start' }
);

const getSortOptionLabel = option => {
  if (option === SIDEBAR_SORT_KEYS.CREATED_DESC) {
    return t('SIDEBAR.SORT_OPTIONS.CREATED_DESC');
  }

  if (option === SIDEBAR_SORT_KEYS.CREATED_ASC) {
    return t('SIDEBAR.SORT_OPTIONS.CREATED_ASC');
  }

  if (option === SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC) {
    return t('SIDEBAR.SORT_OPTIONS.ALPHABETICAL_ASC');
  }

  if (option === SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC) {
    return t('SIDEBAR.SORT_OPTIONS.ALPHABETICAL_DESC');
  }

  if (option === SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC) {
    return t('SIDEBAR.SORT_OPTIONS.UNREAD_COUNT_DESC');
  }

  if (option === SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC) {
    return t('SIDEBAR.SORT_OPTIONS.UNREAD_COUNT_ASC');
  }

  return '';
};

const translatedOptions = computed(() =>
  props.options.map(option => ({
    value: option,
    label: getSortOptionLabel(option),
  }))
);

const activeSortLabel = computed(() => {
  const selectedOption = translatedOptions.value.find(
    option => option.value === props.activeSort
  );

  return selectedOption?.label || t('SIDEBAR.SORT_BY');
});

const closeMenu = () => {
  if (isOpen.value) {
    toggleOpen(false);
  }
};

const toggleMenu = async () => {
  toggleOpen();

  if (isOpen.value) {
    await nextTick();
    updatePosition();
  }
};

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  closeMenu();
};

const handleSortChange = sortBy => {
  emit('update:sort', sortBy);
  closeMenu();
};
</script>

<template>
  <div
    ref="triggerRef"
    class="relative invisible flex-shrink-0 opacity-0 pointer-events-none transition-opacity duration-150 group-hover/sidebar-section:visible group-hover/sidebar-section:opacity-100 group-hover/sidebar-section:pointer-events-auto"
    :class="{ '!visible !opacity-100 !pointer-events-auto': isOpen }"
  >
    <Button
      :title="t('SIDEBAR.SORT_TOOLTIP')"
      icon="i-lucide-arrow-up-down"
      ghost
      slate
      xs
      class="!size-6"
      :class="{ '!bg-n-alpha-2': isOpen }"
      @click.stop="toggleMenu"
    />
    <TeleportWithDirection>
      <div
        v-if="isOpen"
        ref="popoverRef"
        v-on-click-outside="handleClickOutside"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="flex w-64 items-center justify-between gap-3 rounded-xl bg-n-alpha-3 p-3 shadow-lg outline outline-1 outline-n-container backdrop-blur-[100px]"
      >
        <span class="min-w-0 flex-1 truncate text-sm text-n-slate-12">
          {{ t('SIDEBAR.SORT_BY') }}
        </span>
        <SelectMenu
          :model-value="activeSort"
          :options="translatedOptions"
          :label="activeSortLabel"
          @update:model-value="handleSortChange"
        />
      </div>
    </TeleportWithDirection>
  </div>
</template>
