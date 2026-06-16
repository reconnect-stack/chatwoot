import { computed, onMounted } from 'vue';
import { storeToRefs } from 'pinia';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';
import TasksAPI from 'dashboard/api/captain/tasks';

/**
 * Cleans and normalizes a list of labels.
 * @param {string} labels - A comma-separated string of labels.
 * @returns {string[]} An array of cleaned and unique labels.
 */
const cleanLabels = labels => {
  return labels
    .toLowerCase()
    .split(',')
    .filter(label => label.trim())
    .map(label => label.trim())
    .filter((label, index, self) => self.indexOf(label) === index);
};

export function useLabelSuggestions() {
  const { isCloudFeatureEnabled } = useAccount();
  const currentChat = useMapGetter('getSelectedChat');
  const captainConfigStore = useCaptainConfigStore();
  const { externalAssistant, features } = storeToRefs(captainConfigStore);
  const conversationId = computed(() => currentChat.value?.id);

  const externalAssistantEnabled = computed(
    () =>
      externalAssistant.value?.enabled === true &&
      !!externalAssistant.value?.service_url
  );

  const captainTasksEnabled = computed(() => {
    return (
      isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS) ||
      externalAssistantEnabled.value
    );
  });

  const isLabelSuggestionFeatureEnabled = computed(() => {
    return (
      externalAssistantEnabled.value ||
      features.value.label_suggestion?.enabled === true
    );
  });

  /**
   * Gets label suggestions for the current conversation.
   * @returns {Promise<string[]>} An array of suggested labels.
   */
  const getLabelSuggestions = async () => {
    if (!conversationId.value) return [];

    try {
      const result = await TasksAPI.labelSuggestion(conversationId.value);
      const {
        data: { message: labels },
      } = result;
      return cleanLabels(labels);
    } catch {
      return [];
    }
  };

  onMounted(() => {
    captainConfigStore.fetch();
  });

  return {
    captainTasksEnabled,
    isLabelSuggestionFeatureEnabled,
    getLabelSuggestions,
  };
}
