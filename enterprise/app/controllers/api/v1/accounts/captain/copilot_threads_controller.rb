class Api::V1::Accounts::Captain::CopilotThreadsController < Api::V1::Accounts::BaseController
  before_action :ensure_message, only: :create

  def index
    @copilot_threads = Current.account.copilot_threads
                              .where(user_id: Current.user.id)
                              .includes(:user, :assistant)
                              .order(created_at: :desc)
                              .page(permitted_params[:page] || 1)
                              .per(5)
  end

  def create
    return render json: external_thread_response if external_assistant_enabled?

    ActiveRecord::Base.transaction do
      @copilot_thread = Current.account.copilot_threads.create!(
        title: copilot_thread_params[:message],
        user: Current.user,
        assistant: assistant
      )

      copilot_message = @copilot_thread.copilot_messages.create!(
        message_type: :user,
        message: { content: copilot_thread_params[:message] }
      )

      build_copilot_response(copilot_message)
    end
  rescue Captain::ExternalAssistant::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def build_copilot_response(copilot_message)
    if Current.account.usage_limits[:captain][:responses][:current_available].positive?
      copilot_message.enqueue_response_job(copilot_thread_params[:conversation_id], Current.user.id)
    else
      copilot_message.copilot_thread.copilot_messages.create!(
        message_type: :assistant,
        message: { content: I18n.t('captain.copilot_limit') }
      )
    end
  end

  def ensure_message
    return render_could_not_create_error(I18n.t('captain.copilot_message_required')) if copilot_thread_params[:message].blank?
  end

  def assistant
    Current.account.captain_assistants.find(copilot_thread_params[:assistant_id])
  end

  def external_thread_response
    thread_id = (Time.current.to_f * 1000).to_i
    assistant_response = external_assistant_client(thread_id: thread_id, history: []).perform
    build_external_thread_payload(assistant_response[:thread_id].presence || thread_id, assistant_response)
  end

  def external_assistant_client(thread_id:, history:)
    Captain::ExternalAssistant::Client.new(
      account: Current.account,
      user: Current.user,
      config: external_assistant_config,
      message: copilot_thread_params[:message],
      conversation_id: copilot_thread_params[:conversation_id],
      thread_id: thread_id,
      history: history
    )
  end

  def build_external_thread_payload(thread_id, assistant_response)
    thread = external_copilot_thread_payload(thread_id)
    {
      **thread,
      messages: [
        external_copilot_message_payload(thread, copilot_thread_params[:message], 'user'),
        external_copilot_message_payload(thread, assistant_response[:content], 'assistant', trace_id: assistant_response[:trace_id])
      ]
    }
  end

  def external_copilot_thread_payload(thread_id)
    {
      id: thread_id,
      title: copilot_thread_params[:message],
      created_at: Time.current.to_i,
      user: Current.user.push_event_data,
      assistant: external_assistant_payload,
      account_id: Current.account.id
    }
  end

  def external_copilot_message_payload(thread, content, message_type, trace_id: nil)
    {
      id: ((Time.current.to_f * 1000).to_i + (message_type == 'user' ? 1 : 2)),
      message: { content: content, trace_id: trace_id }.compact,
      message_type: message_type,
      created_at: Time.current.to_i,
      copilot_thread: thread,
      account_id: Current.account.id
    }
  end

  def external_assistant_payload
    {
      id: external_assistant_config.assistant_id.presence || 'external-assistant',
      name: external_assistant_config.assistant_id.presence || 'External assistant'
    }
  end

  def external_assistant_enabled?
    external_assistant_config&.enabled? && external_assistant_config.service_url.present?
  end

  def external_assistant_config
    @external_assistant_config ||= Current.account.captain_external_assistant_config
  end

  def copilot_thread_params
    params.permit(:message, :assistant_id, :conversation_id)
  end

  def permitted_params
    params.permit(:page)
  end
end
