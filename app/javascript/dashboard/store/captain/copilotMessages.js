import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'CopilotMessages',
  API: CopilotMessagesAPI,
  getters: {
    getMessagesByThreadId: state => copilotThreadId => {
      return state.records
        .filter(
          record =>
            String(record.copilot_thread?.id) === String(copilotThreadId)
        )
        .sort((a, b) => a.id - b.id);
    },
  },
  actions: mutationTypes => ({
    upsert({ commit }, data) {
      commit(mutationTypes.UPSERT, data);
    },
  }),
});
