<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  channel: { type: Object, required: true },
  connectedInbox: { type: Object, default: null },
});

defineEmits(['connect']);

const { t } = useI18n();

const connected = computed(() => Boolean(props.connectedInbox));
// Prefer the real connected account's name over the detected handle — the user
// may have connected a different account than the one we detected.
const connectedName = computed(
  () =>
    props.connectedInbox?.name || props.channel.handle || props.channel.label
);
</script>

<template>
  <div class="flex items-center justify-between gap-3 px-3 py-3">
    <div class="flex items-center gap-2 min-w-0">
      <ChannelIcon
        :inbox="channel.inbox"
        use-brand-icon
        class="size-4 flex-shrink-0"
        :class="{ grayscale: !connected }"
      />
      <span class="text-sm font-medium text-n-slate-12">
        {{ channel.label }}
      </span>
    </div>
    <div
      v-if="connected"
      class="flex items-center gap-2 flex-shrink-0 text-sm text-n-slate-11"
    >
      <span class="truncate">{{ connectedName }}</span>
      <span class="w-px h-4 bg-n-weak" />
      <span>{{ t('ONBOARDING_INBOX_SETUP.CHANNELS.CONNECTED') }}</span>
    </div>
    <NextButton v-else outline slate xs @click="$emit('connect', channel)">
      <span class="text-n-blue-11 truncate">
        {{
          t('ONBOARDING_INBOX_SETUP.CHANNELS.CONNECT', {
            name: channel.handle || channel.label,
          })
        }}
      </span>
    </NextButton>
  </div>
</template>
