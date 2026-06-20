/* global axios */
import ApiClient from '../ApiClient';

class CopilotMessages extends ApiClient {
  constructor() {
    super('captain/copilot_threads', { accountScoped: true });
  }

  get(threadId) {
    return axios.get(`${this.url}/${threadId}/copilot_messages`);
  }

  create({ threadId, ...rest }) {
    return axios.post(`${this.url}/${threadId}/copilot_messages`, rest);
  }

  sendFeedback({
    threadId,
    messageId,
    rating,
    traceId,
    conversationId,
    assistantId,
  }) {
    return axios.post(`${this.url}/${threadId}/feedback`, {
      message_id: messageId,
      rating,
      trace_id: traceId,
      conversation_id: conversationId,
      assistant_id: assistantId,
    });
  }

  removeFeedback({ threadId, messageId }) {
    return axios.delete(`${this.url}/${threadId}/feedback`, {
      params: { message_id: messageId },
    });
  }
}

export default new CopilotMessages();
