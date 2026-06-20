class Api::V1::Accounts::Captain::CopilotMessagesController < Api::V1::Accounts::BaseController
  before_action :set_copilot_thread, unless: :external_assistant_enabled?

  def index
    return render json: { payload: [], meta: { total_count: 0, page: 1 } } if external_assistant_enabled?

    @copilot_messages = @copilot_thread
                        .copilot_messages
                        .includes(:copilot_thread)
                        .order(created_at: :asc)
                        .page(permitted_params[:page] || 1)
                        .per(1000)
  end

  def create
    return render json: external_message_response if external_assistant_enabled?

    @copilot_message = @copilot_thread.copilot_messages.create!(
      message: { content: params[:message] },
      message_type: :user
    )
    @copilot_message.enqueue_response_job(params[:conversation_id], Current.user.id)
  rescue Captain::ExternalAssistant::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def external_message_response
    assistant_response = external_assistant_client.perform
    thread = external_copilot_thread_payload

    external_copilot_message_payload(thread, assistant_response[:content], 'assistant', trace_id: assistant_response[:trace_id]).merge(
      user_message: external_copilot_message_payload(thread, copilot_message_params[:message], 'user', id_offset: -1)
    )
  end

  def external_assistant_client
    Captain::ExternalAssistant::Client.new(
      account: Current.account,
      user: Current.user,
      config: external_assistant_config,
      message: copilot_message_params[:message],
      conversation_id: copilot_message_params[:conversation_id],
      thread_id: params[:copilot_thread_id],
      history: copilot_message_params[:history] || []
    )
  end

  def external_copilot_thread_payload
    {
      id: params[:copilot_thread_id],
      title: copilot_message_params[:message],
      created_at: Time.current.to_i,
      user: Current.user.push_event_data,
      assistant: external_assistant_payload,
      account_id: Current.account.id
    }
  end

  def external_copilot_message_payload(thread, content, message_type, id_offset: 0, trace_id: nil)
    {
      id: ((Time.current.to_f * 1000).to_i + id_offset),
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

  def set_copilot_thread
    @copilot_thread = Current.account.copilot_threads.find_by!(
      id: params[:copilot_thread_id],
      user: Current.user
    )
  end

  def permitted_params
    params.permit(:page)
  end

  def copilot_message_params
    params.permit(:message, :assistant_id, :conversation_id, history: [:role, :content])
  end
end
