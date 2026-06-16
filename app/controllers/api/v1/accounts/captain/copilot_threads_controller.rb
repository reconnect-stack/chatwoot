class Api::V1::Accounts::Captain::CopilotThreadsController < Api::V1::Accounts::BaseController
  before_action :ensure_message, only: :create

  def index
    render json: { payload: [], meta: { total_count: 0, page: 1 } }
  end

  def create
    render json: external_thread_response
  rescue Captain::ExternalAssistant::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def external_thread_response
    thread_id = (Time.current.to_f * 1000).to_i
    assistant_response = external_assistant_client(thread_id: thread_id, history: []).perform
    build_thread_payload(assistant_response[:thread_id].presence || thread_id, assistant_response)
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

  def build_thread_payload(thread_id, assistant_response)
    thread = copilot_thread_payload(thread_id)
    {
      **thread,
      messages: [
        copilot_message_payload(thread, copilot_thread_params[:message], 'user'),
        copilot_message_payload(thread, assistant_response[:content], 'assistant')
      ]
    }
  end

  def copilot_thread_payload(thread_id)
    {
      id: thread_id,
      title: copilot_thread_params[:message],
      created_at: Time.current.to_i,
      user: Current.user.push_event_data,
      assistant: external_assistant_payload,
      account_id: Current.account.id
    }
  end

  def copilot_message_payload(thread, content, message_type)
    {
      id: ((Time.current.to_f * 1000).to_i + (message_type == 'user' ? 1 : 2)),
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
    return render_could_not_create_error(I18n.t('captain.copilot_message_required')) if copilot_thread_params[:message].blank?
  end

  def copilot_thread_params
    params.permit(:message, :assistant_id, :conversation_id)
  end
end
