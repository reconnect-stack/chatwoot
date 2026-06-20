<script setup>
import { computed, ref } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useTrack } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  isLastMessage: {
    type: Boolean,
    default: false,
  },
  message: {
    type: Object,
    required: true,
  },
  messageId: {
    type: [Number, String],
    default: null,
  },
  threadId: {
    type: [Number, String],
    default: null,
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['rate']);

const hasEmptyMessageContent = computed(() => !props.message?.content);

const showUseButton = computed(() => {
  return (
    !hasEmptyMessageContent.value &&
    props.message.reply_suggestion &&
    props.isLastMessage
  );
});

const canRate = computed(
  () =>
    !hasEmptyMessageContent.value &&
    props.messageId != null &&
    props.threadId != null
);

const currentRating = ref(null);

const submitRating = rating => {
  const newRating = currentRating.value === rating ? null : rating;
  currentRating.value = newRating;
  emit('rate', {
    messageId: props.messageId,
    threadId: props.threadId,
    traceId: props.message?.trace_id,
    rating: newRating,
  });
  useTrack(COPILOT_EVENTS.RATE_CAPTAIN_RESPONSE, { rating: newRating });
};

const messageContent = computed(() => {
  const formatter = new MessageFormatter(props.message.content);
  return formatter.formattedMessage;
});

const insertIntoRichEditor = computed(() => {
  return [INBOX_TYPES.WEB, INBOX_TYPES.EMAIL].includes(
    props.conversationInboxType
  );
});

const useCopilotResponse = () => {
  if (insertIntoRichEditor.value) {
    emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, props.message?.content);
  } else {
    emitter.emit(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, props.message?.content);
  }
  useTrack(COPILOT_EVENTS.USE_CAPTAIN_RESPONSE);
};
</script>

<template>
  <div class="flex flex-col gap-1 text-n-slate-12">
    <div class="font-medium">{{ $t('CAPTAIN.NAME') }}</div>
    <span v-if="hasEmptyMessageContent" class="text-n-ruby-11">
      {{ $t('CAPTAIN.COPILOT.EMPTY_MESSAGE') }}
    </span>
    <div
      v-else
      v-dompurify-html="messageContent"
      class="prose-sm break-words"
    />
    <div class="flex flex-row items-center gap-1 mt-1">
      <Button
        v-if="showUseButton"
        :label="$t('CAPTAIN.COPILOT.USE')"
        faded
        sm
        slate
        @click="useCopilotResponse"
      />
      <template v-if="canRate">
        <Button
          v-tooltip="$t('CAPTAIN.COPILOT.FEEDBACK.LIKE')"
          icon="i-lucide-thumbs-up"
          ghost
          xs
          :color="currentRating === 'up' ? 'teal' : 'slate'"
          @click="submitRating('up')"
        />
        <Button
          v-tooltip="$t('CAPTAIN.COPILOT.FEEDBACK.DISLIKE')"
          icon="i-lucide-thumbs-down"
          ghost
          xs
          :color="currentRating === 'down' ? 'ruby' : 'slate'"
          @click="submitRating('down')"
        />
      </template>
    </div>
  </div>
</template>
