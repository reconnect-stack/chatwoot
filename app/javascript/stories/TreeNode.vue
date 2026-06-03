<script setup>
import { reactive } from 'vue';

// Recursive sidebar node. Each instance owns the collapsed state of its own
// direct child groups, so nesting just works. Plain buttons/divs (no <ul>/<li>)
// avoid the list markers the dashboard stylesheet injects.
const props = defineProps({
  nodes: { type: Array, required: true },
  selectedPath: { type: String, default: '' },
  forceExpand: { type: Boolean, default: false },
  depth: { type: Number, default: 0 },
});

defineEmits(['select']);

// Default: top-level (L1) groups open, everything deeper collapsed.
// `overrides` holds the explicit open/closed state once the user toggles a group.
const overrides = reactive({});
const isOpen = name => {
  if (props.forceExpand) return true;
  if (name in overrides) return overrides[name];
  return props.depth === 0;
};
const toggle = name => {
  overrides[name] = !isOpen(name);
};
</script>

<template>
  <div class="flex flex-col gap-px">
    <template v-for="node in nodes" :key="node.name">
      <div v-if="node.type === 'group'" class="flex flex-col">
        <button
          type="button"
          class="flex items-center w-full gap-1.5 px-2 py-1 rounded-md group text-n-slate-11 hover:bg-n-alpha-1"
          @click="toggle(node.name)"
        >
          <span
            class="transition-transform i-lucide-chevron-right size-3.5 shrink-0 text-n-slate-10"
            :class="{ 'rotate-90': isOpen(node.name) }"
          />
          <span
            class="text-xs font-semibold tracking-wide uppercase truncate text-n-slate-10"
          >
            {{ node.name }}
          </span>
        </button>
        <div
          v-show="isOpen(node.name)"
          class="ml-2.5 pl-2 border-l border-n-weak"
        >
          <TreeNode
            :nodes="node.children"
            :selected-path="selectedPath"
            :force-expand="forceExpand"
            :depth="depth + 1"
            @select="$emit('select', $event)"
          />
        </div>
      </div>
      <button
        v-else
        type="button"
        class="block w-full px-2 py-1 ml-1 text-sm text-left truncate transition-colors rounded-md"
        :class="
          node.path === selectedPath
            ? 'bg-n-brand/10 text-n-brand font-medium'
            : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
        "
        @click="$emit('select', node.path)"
      >
        {{ node.name }}
      </button>
    </template>
  </div>
</template>
