<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { storeToRefs } from 'pinia';
import { useAlert } from 'dashboard/composables';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const { t } = useI18n();

const captainConfigStore = useCaptainConfigStore();
const { externalAssistant, uiFlags } = storeToRefs(captainConfigStore);

const isLoading = computed(() => uiFlags.value.isFetching);
const isSavingExternalAssistant = ref(false);
const externalAssistantForm = ref({
  enabled: false,
  service_url: '',
  access_token: '',
  assistant_id: '',
  settings: {
    send_conversation_context: true,
    send_contact_details: true,
    send_private_notes: false,
  },
});

const externalAssistantContextOptions = computed(() => [
  {
    key: 'send_conversation_context',
    label: t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.CONTEXT.CONVERSATION'),
  },
  {
    key: 'send_contact_details',
    label: t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.CONTEXT.CONTACT'),
  },
  {
    key: 'send_private_notes',
    label: t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.CONTEXT.PRIVATE_NOTES'),
  },
]);

function syncExternalAssistantForm(config = {}) {
  const settings = config.settings || {};
  externalAssistantForm.value = {
    enabled: config.enabled === true,
    service_url: config.service_url || '',
    access_token: '',
    assistant_id: config.assistant_id || '',
    settings: {
      send_conversation_context: settings.send_conversation_context !== false,
      send_contact_details: settings.send_contact_details !== false,
      send_private_notes: settings.send_private_notes === true,
    },
  };
}

async function handleExternalAssistantSubmit() {
  try {
    isSavingExternalAssistant.value = true;
    const form = externalAssistantForm.value;
    const payload = {
      enabled: form.enabled,
      service_url: form.service_url,
      assistant_id: form.assistant_id,
      settings: form.settings,
    };

    if (form.access_token) {
      payload.access_token = form.access_token;
    }

    await captainConfigStore.updatePreferences({
      external_assistant: payload,
    });
    useAlert(t('CAPTAIN_SETTINGS.API.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN_SETTINGS.API.ERROR'));
    captainConfigStore.fetch();
  } finally {
    isSavingExternalAssistant.value = false;
  }
}

watch(externalAssistant, syncExternalAssistantForm, { immediate: true });

onMounted(() => {
  captainConfigStore.fetch();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="t('CAPTAIN_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('CAPTAIN_SETTINGS.TITLE')"
        :description="t('CAPTAIN_SETTINGS.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-1">
        <SectionLayout
          :title="t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.TITLE')"
          :description="t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.DESCRIPTION')"
        >
          <form
            class="grid gap-5"
            @submit.prevent="handleExternalAssistantSubmit"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="min-w-0">
                <h5 class="text-heading-3 text-n-slate-12">
                  {{ t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ENABLED.TITLE') }}
                </h5>
                <p class="mt-1 mb-0 text-body-small text-n-slate-11">
                  {{
                    t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ENABLED.DESCRIPTION')
                  }}
                </p>
              </div>
              <Switch v-model="externalAssistantForm.enabled" />
            </div>

            <div class="grid gap-4 md:grid-cols-2">
              <Input
                v-model="externalAssistantForm.service_url"
                :label="t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.SERVICE_URL')"
                :placeholder="
                  t(
                    'CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.SERVICE_URL_PLACEHOLDER'
                  )
                "
              />
              <Input
                v-model="externalAssistantForm.assistant_id"
                :label="t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ASSISTANT_ID')"
                :placeholder="
                  t(
                    'CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ASSISTANT_ID_PLACEHOLDER'
                  )
                "
              />
            </div>

            <Input
              v-model="externalAssistantForm.access_token"
              type="password"
              :label="t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ACCESS_TOKEN')"
              :placeholder="
                externalAssistant.access_token_configured
                  ? t(
                      'CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ACCESS_TOKEN_CONFIGURED'
                    )
                  : t(
                      'CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ACCESS_TOKEN_PLACEHOLDER'
                    )
              "
              :message="
                externalAssistant.access_token_configured
                  ? t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.ACCESS_TOKEN_HELP')
                  : ''
              "
            />

            <div class="grid gap-3">
              <p class="mb-0 text-heading-3 text-n-slate-12">
                {{ t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.CONTEXT.TITLE') }}
              </p>
              <label
                v-for="option in externalAssistantContextOptions"
                :key="option.key"
                class="flex items-center gap-3 text-sm text-n-slate-12"
              >
                <Checkbox
                  v-model="externalAssistantForm.settings[option.key]"
                />
                <span>{{ option.label }}</span>
              </label>
            </div>

            <div class="flex justify-end">
              <Button
                type="submit"
                :label="t('CAPTAIN_SETTINGS.EXTERNAL_ASSISTANT.SAVE')"
                :is-loading="isSavingExternalAssistant"
                :disabled="isSavingExternalAssistant"
              />
            </div>
          </form>
        </SectionLayout>
      </div>
    </template>
  </SettingsLayout>
</template>
