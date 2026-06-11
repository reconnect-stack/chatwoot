<script setup>
import { computed, nextTick, onBeforeUnmount, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import Button from 'dashboard/components-next/button/Button.vue';
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

const SORT_OPTION_GROUPS = [
  {
    key: 'created',
    options: [SIDEBAR_SORT_KEYS.CREATED_DESC, SIDEBAR_SORT_KEYS.CREATED_ASC],
  },
  {
    key: 'alphabetical',
    options: [
      SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
      SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
    ],
  },
  {
    key: 'unread_count',
    options: [
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
    ],
  },
];

const { t } = useI18n();
const isOpen = ref(false);
const triggerRef = ref(null);
const popoverRef = ref(null);
let closeTimer;

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

const getSortGroupLabel = groupKey => {
  if (groupKey === 'created') {
    return t('SIDEBAR.SORT_GROUPS.CREATED');
  }

  if (groupKey === 'alphabetical') {
    return t('SIDEBAR.SORT_GROUPS.ALPHABETICAL');
  }

  if (groupKey === 'unread_count') {
    return t('SIDEBAR.SORT_GROUPS.UNREAD_COUNT');
  }

  return '';
};

const translatedOptions = computed(() =>
  props.options.map(option => ({
    value: option,
    label: getSortOptionLabel(option),
  }))
);

const groupedOptions = computed(() =>
  SORT_OPTION_GROUPS.map(group => ({
    key: group.key,
    label: getSortGroupLabel(group.key),
    options: translatedOptions.value.filter(option =>
      group.options.includes(option.value)
    ),
  })).filter(group => group.options.length)
);

const clearCloseTimer = () => {
  if (closeTimer) {
    clearTimeout(closeTimer);
    closeTimer = null;
  }
};

const openMenu = async () => {
  clearCloseTimer();
  isOpen.value = true;

  await nextTick();
  updatePosition();
};

const closeMenu = () => {
  clearCloseTimer();
  isOpen.value = false;
};

const scheduleClose = () => {
  clearCloseTimer();
  closeTimer = setTimeout(closeMenu, 150);
};

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  closeMenu();
};

const handleSortChange = sortBy => {
  emit('update:sort', sortBy);
  closeMenu();
};

onBeforeUnmount(clearCloseTimer);
</script>

<template>
  <div
    ref="triggerRef"
    class="relative invisible flex-shrink-0 opacity-0 pointer-events-none transition-opacity duration-150 group-hover/sidebar-section:visible group-hover/sidebar-section:opacity-100 group-hover/sidebar-section:pointer-events-auto"
    :class="{ '!visible !opacity-100 !pointer-events-auto': isOpen }"
    @mouseenter="openMenu"
    @mouseleave="scheduleClose"
  >
    <Button
      :title="t('SIDEBAR.SORT_TOOLTIP')"
      icon="i-lucide-arrow-up-down"
      ghost
      slate
      xs
      class="!size-6"
      :class="{ '!bg-n-alpha-2': isOpen }"
      @click.stop="openMenu"
    />
    <TeleportWithDirection>
      <div
        v-if="isOpen"
        ref="popoverRef"
        v-on-click-outside="handleClickOutside"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="flex w-72 flex-col gap-1 overflow-y-auto rounded-xl bg-n-alpha-3 p-2 shadow-lg outline outline-1 outline-n-container backdrop-blur-[100px]"
        role="menu"
        @mouseenter="clearCloseTimer"
        @mouseleave="scheduleClose"
      >
        <div
          v-for="group in groupedOptions"
          :key="group.key"
          class="flex flex-col gap-0.5 py-1"
          role="group"
          :aria-label="group.label"
        >
          <span class="px-2 py-1 text-sm font-medium text-n-slate-10">
            {{ group.label }}
          </span>
          <button
            v-for="option in group.options"
            :key="option.value"
            type="button"
            class="flex h-9 w-full items-center justify-between gap-3 rounded-lg px-2 text-left text-sm font-medium text-n-slate-12 hover:bg-n-alpha-2 focus-visible:bg-n-alpha-2 focus-visible:outline-none"
            role="menuitemradio"
            :aria-checked="option.value === activeSort"
            @click.stop="handleSortChange(option.value)"
          >
            <span class="min-w-0 flex-1 truncate">
              {{ option.label }}
            </span>
            <span
              v-if="option.value === activeSort"
              class="i-lucide-check size-4 flex-shrink-0 text-n-slate-11"
            />
          </button>
        </div>
      </div>
    </TeleportWithDirection>
  </div>
</template>
