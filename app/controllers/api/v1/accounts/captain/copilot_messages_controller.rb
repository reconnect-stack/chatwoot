class Api::V1::Accounts::Captain::CopilotMessagesController < Api::V1::Accounts::BaseController
  before_action :ensure_message, only: :create

  def index
    render json: { payload: [], meta: { total_count: 0, page: 1 } }
  end

  def create
    render json: external_message_response
  rescue Captain::ExternalAssistant::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def external_message_response
    assistant_response = external_assistant_client.perform
    thread = copilot_thread_payload

    copilot_message_payload(thread, assistant_response[:content], 'assistant').merge(
      user_message: copilot_message_payload(thread, copilot_message_params[:message], 'user', id_offset: -1)
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

  def copilot_thread_payload
    {
      id: params[:copilot_thread_id],
      title: copilot_message_params[:message],
      created_at: Time.current.to_i,
      user: Current.user.push_event_data,
      assistant: external_assistant_payload,
      account_id: Current.account.id
    }
  end

  def copilot_message_payload(thread, content, message_type, id_offset: 0)
    {
      id: ((Time.current.to_f * 1000).to_i + id_offset),
      message: { content: content },
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

  def external_assistant_config
    @external_assistant_config ||= Current.account.captain_external_assistant_config
    return @external_assistant_config if @external_assistant_config&.enabled?

    raise Captain::ExternalAssistant::Error, 'External assistant is not configured'
  end

  def ensure_message
    return render_could_not_create_error(I18n.t('captain.copilot_message_required')) if copilot_message_params[:message].blank?
  end

  def copilot_message_params
    params.permit(:message, :assistant_id, :conversation_id, history: [:role, :content])
  end
end
