class Api::V1::Accounts::Captain::CopilotFeedbacksController < Api::V1::Accounts::BaseController
  before_action :validate_create_params, only: :create

  def create
    feedback = upsert_feedback
    Captain::ExternalAssistant::SubmitFeedbackJob.perform_later(feedback) if forward_feedback?(feedback)
    render json: feedback_payload(feedback)
  end

  def destroy
    existing_feedback&.destroy
    head :no_content
  end

  private

  def upsert_feedback
    feedback = scoped_feedbacks.find_or_initialize_by(copilot_message_id: feedback_params[:message_id].to_s)
    feedback.update!(
      rating: feedback_params[:rating],
      trace_id: feedback_params[:trace_id],
      conversation_id: feedback_params[:conversation_id],
      assistant_id: feedback_params[:assistant_id]
    )
    feedback
  end

  def existing_feedback
    scoped_feedbacks.find_by(copilot_message_id: feedback_params[:message_id].to_s)
  end

  def scoped_feedbacks
    Current.account.captain_copilot_message_feedbacks.where(
      user: Current.user,
      copilot_thread_id: params[:copilot_thread_id].to_s
    )
  end

  def forward_feedback?(feedback)
    feedback.trace_id.present? &&
      external_assistant_config&.enabled? &&
      external_assistant_config.service_url.present?
  end

  def external_assistant_config
    @external_assistant_config ||= Current.account.captain_external_assistant_config
  end

  def validate_create_params
    return render_could_not_create_error('message_id is required') if feedback_params[:message_id].blank?
    return if Captain::CopilotMessageFeedback::RATINGS.include?(feedback_params[:rating])

    render_could_not_create_error('rating must be up or down')
  end

  def feedback_payload(feedback)
    {
      id: feedback.id,
      message_id: feedback.copilot_message_id,
      copilot_thread_id: feedback.copilot_thread_id,
      rating: feedback.rating
    }
  end

  def feedback_params
    params.permit(:message_id, :rating, :trace_id, :conversation_id, :assistant_id)
  end
end
