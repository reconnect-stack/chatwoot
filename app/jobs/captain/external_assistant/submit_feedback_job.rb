class Captain::ExternalAssistant::SubmitFeedbackJob < ApplicationJob
  queue_as :low

  def perform(feedback)
    return if feedback.trace_id.blank?

    config = feedback.account.captain_external_assistant_config
    return unless config&.enabled? && config.service_url.present?

    Captain::ExternalAssistant::FeedbackClient.new(
      config: config,
      trace_id: feedback.trace_id,
      rating: feedback.rating,
      user: feedback.user,
      thread_id: feedback.copilot_thread_id,
      conversation_id: feedback.conversation_id
    ).perform
  end
end
