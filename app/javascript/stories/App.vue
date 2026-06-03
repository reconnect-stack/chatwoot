<script setup>
import { ref, computed, defineAsyncComponent } from 'vue';
import { stories, buildTree } from './registry';
import TreeNode from './TreeNode.vue';
import StoryFrame from './StoryFrame.vue';

const query = ref('');
const filteredStories = computed(() => {
  const term = query.value.trim().toLowerCase();
  if (!term) return stories;
  return stories.filter(story => story.title.toLowerCase().includes(term));
});
const tree = computed(() => buildTree(filteredStories.value));
const isSearching = computed(() => query.value.trim().length > 0);

function pathFromHash() {
  const hash = decodeURIComponent(window.location.hash.replace(/^#/, ''));
  return stories.find(story => story.path === hash)?.path;
}

const selectedPath = ref(pathFromHash() || stories[0]?.path || '');
const current = computed(() =>
  stories.find(story => story.path === selectedPath.value)
);
const StoryComponent = computed(() =>
  current.value ? defineAsyncComponent(current.value.loader) : null
);

function select(path) {
  selectedPath.value = path;
  window.location.hash = encodeURIComponent(path);
}

const isDark = ref(false);
function toggleDark() {
  isDark.value = !isDark.value;
  document.documentElement.classList.toggle('dark', isDark.value);
}

// Scoped to the preview canvas only (see the <main :dir> below), so the
// sidebar stays LTR while stories can be inspected in RTL.
const isRtl = ref(false);
function toggleDir() {
  isRtl.value = !isRtl.value;
}

// Remount the active story on every hot update so a fixed file clears the
// error boundary (otherwise a caught error stays latched until a full reload).
const hmrTick = ref(0);
if (import.meta.hot) {
  import.meta.hot.on('vite:afterUpdate', () => {
    hmrTick.value += 1;
  });
}
</script>

<template>
  <div
    class="flex w-screen h-screen overflow-hidden bg-n-background text-n-slate-12"
  >
    <aside
      dir="ltr"
      class="flex flex-col border-r w-72 shrink-0 border-n-weak bg-n-solid-1"
    >
      <div
        class="flex items-center justify-between h-12 gap-2 px-4 border-b shrink-0 border-n-weak"
      >
        <span class="text-sm font-semibold text-n-slate-12">
          @chatwoot/design
        </span>
        <div class="flex items-center gap-1">
          <button
            type="button"
            class="px-2 py-1 text-xs font-medium uppercase rounded-md text-n-slate-11 hover:bg-n-alpha-1"
            @click="toggleDir"
          >
            {{ isRtl ? 'RTL' : 'LTR' }}
          </button>
          <button
            type="button"
            class="px-2 py-1 text-sm rounded-md text-n-slate-11 hover:bg-n-alpha-1"
            @click="toggleDark"
          >
            {{ isDark ? 'Light' : 'Dark' }}
          </button>
        </div>
      </div>
      <div class="p-3 border-b shrink-0 border-n-weak">
        <input
          v-model="query"
          type="search"
          placeholder="Search stories"
          class="w-full px-3 py-1.5 text-sm rounded-md border outline-none border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:border-n-brand"
        />
      </div>
      <nav class="flex-1 p-2 overflow-y-auto">
        <TreeNode
          :nodes="tree"
          :selected-path="selectedPath"
          :force-expand="isSearching"
          @select="select"
        />
        <p
          v-if="!filteredStories.length"
          class="px-2 py-4 text-sm text-n-slate-10"
        >
          No stories match "{{ query }}".
        </p>
      </nav>
    </aside>
    <main :dir="isRtl ? 'rtl' : 'ltr'" class="flex-1 min-w-0 overflow-hidden">
      <StoryFrame
        v-if="StoryComponent"
        :key="`${selectedPath}:${hmrTick}`"
        :component="StoryComponent"
      />
      <div
        v-else
        class="flex items-center justify-center h-full text-n-slate-10"
      >
        Select a story to preview.
      </div>
    </main>
  </div>
</template>
