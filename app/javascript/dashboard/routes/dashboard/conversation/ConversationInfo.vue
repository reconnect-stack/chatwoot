<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getLanguageName } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import ContactDetailsItem from './ContactDetailsItem.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';

const props = defineProps({
  conversationAttributes: {
    type: Object,
    default: () => ({}),
  },
  contactAttributes: {
    type: Object,
    default: () => ({}),
  },
  referralAttributes: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const referer = computed(() => props.conversationAttributes.referer);
const initiatedAt = computed(
  () => props.conversationAttributes.initiated_at?.timestamp
);

const browserInfo = computed(() => props.conversationAttributes.browser);

const browserName = computed(() => {
  if (!browserInfo.value) return '';
  const { browser_name: name = '', browser_version: version = '' } =
    browserInfo.value;
  return `${name} ${version}`;
});

const browserLanguage = computed(() =>
  getLanguageName(props.conversationAttributes.browser_language)
);

const platformName = computed(() => {
  if (!browserInfo.value) return '';
  const { platform_name: name = '', platform_version: version = '' } =
    browserInfo.value;
  return `${name} ${version}`;
});

const createdAtIp = computed(() => props.contactAttributes.created_at_ip);
const hasReferral = computed(
  () => Object.keys(props.referralAttributes || {}).length > 0
);
const referralTitle = computed(
  () => props.referralAttributes.headline || props.referralAttributes.source_id
);
const referralFields = computed(() =>
  [
    {
      label: t('CONTACT_PANEL.AD_REFERRAL.SOURCE_TYPE'),
      value: props.referralAttributes.source_type,
    },
    {
      label: t('CONTACT_PANEL.AD_REFERRAL.SOURCE_ID'),
      value: props.referralAttributes.source_id,
    },
    {
      label: t('CONTACT_PANEL.AD_REFERRAL.CTWA_CLID'),
      value: props.referralAttributes.ctwa_clid,
    },
  ].filter(field => !!field.value)
);
const referralMediaUrl = computed(
  () =>
    props.referralAttributes.thumbnail_url ||
    props.referralAttributes.image_url ||
    props.referralAttributes.video_url
);
const referralSourceUrl = computed(() => props.referralAttributes.source_url);

const staticElements = computed(() =>
  [
    {
      content: initiatedAt,
      title: 'CONTACT_PANEL.INITIATED_AT',
      key: 'static-initiated-at',
      type: 'static_attribute',
    },
    {
      content: browserLanguage,
      title: 'CONTACT_PANEL.BROWSER_LANGUAGE',
      key: 'static-browser-language',
      type: 'static_attribute',
    },
    {
      content: referer,
      title: 'CONTACT_PANEL.INITIATED_FROM',
      key: 'static-referer',
      type: 'static_attribute',
    },
    {
      content: browserName,
      title: 'CONTACT_PANEL.BROWSER',
      key: 'static-browser',
      type: 'static_attribute',
    },
    {
      content: platformName,
      title: 'CONTACT_PANEL.OS',
      key: 'static-platform',
      type: 'static_attribute',
    },
    {
      content: createdAtIp,
      title: 'CONTACT_PANEL.IP_ADDRESS',
      key: 'static-ip-address',
      type: 'static_attribute',
    },
  ].filter(attribute => !!attribute.content.value)
);
</script>

<template>
  <div class="conversation--details">
    <div v-if="hasReferral" class="px-4 pt-3 pb-4 border-b border-n-weak">
      <div class="flex items-center gap-2 mb-3">
        <i class="i-lucide-megaphone size-4 text-n-brand" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('CONTACT_PANEL.AD_REFERRAL.TITLE') }}
        </span>
      </div>
      <a
        v-if="referralMediaUrl"
        :href="referralMediaUrl"
        target="_blank"
        rel="noopener noreferrer nofollow"
        class="block mb-3 overflow-hidden rounded-md border border-n-weak bg-n-alpha-1"
      >
        <img
          :src="referralMediaUrl"
          :alt="$t('CONTACT_PANEL.AD_REFERRAL.MEDIA_PREVIEW')"
          class="object-cover w-full max-h-40"
        />
      </a>
      <div class="flex flex-col gap-2">
        <div v-if="referralTitle" class="text-sm font-medium text-n-slate-12">
          {{ referralTitle }}
        </div>
        <div v-if="referralAttributes.body" class="text-sm text-n-slate-11">
          {{ referralAttributes.body }}
        </div>
        <div
          v-for="field in referralFields"
          :key="field.label"
          class="flex flex-col gap-0.5"
        >
          <span class="text-xs text-n-slate-10">
            {{ field.label }}
          </span>
          <span class="text-sm break-words text-n-slate-12">
            {{ field.value }}
          </span>
        </div>
        <a
          v-if="referralSourceUrl"
          :href="referralSourceUrl"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="inline-flex items-center gap-1 text-sm text-n-brand hover:underline"
        >
          {{ $t('CONTACT_PANEL.AD_REFERRAL.VIEW_SOURCE') }}
          <i class="i-lucide-external-link size-3" />
        </a>
      </div>
    </div>
    <CustomAttributes
      :static-elements="staticElements"
      attribute-class="conversation--attribute"
      attribute-from="conversation_panel"
      attribute-type="conversation_attribute"
    >
      <template #staticItem="{ element }">
        <ContactDetailsItem
          :key="element.title"
          :title="$t(element.title)"
          :value="element.content.value"
        >
          <a
            v-if="element.key === 'static-referer'"
            :href="element.content.value"
            rel="noopener noreferrer nofollow"
            target="_blank"
            class="text-n-brand"
          >
            {{ element.content.value }}
          </a>
        </ContactDetailsItem>
      </template>
    </CustomAttributes>
  </div>
</template>
