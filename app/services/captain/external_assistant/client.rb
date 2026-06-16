module Captain
  module ExternalAssistant
    class Error < StandardError; end
  end
end

class Captain::ExternalAssistant::Client
  pattr_initialize [
    :account!,
    :user!,
    :config!,
    :message!,
    :conversation_id,
    :thread_id,
    {
      history: [],
      feature_name: nil,
      messages: []
    }
  ]

  def perform
    response = HTTParty.post(
      config.service_url,
      headers: headers,
      body: payload.to_json,
      timeout: 60
    )

    raise Captain::ExternalAssistant::Error, response.body unless response.success?

    parsed_response(response)
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }.tap do |request_headers|
      request_headers['Authorization'] = "Bearer #{config.access_token}" if config.access_token.present?
    end
  end

  def payload
    {
      assistant_id: config.assistant_id,
      account: account_payload,
      user: user_payload,
      conversation: conversation_payload,
      message: message,
      feature_name: feature_name,
      thread_id: thread_id,
      history: history,
      messages: messages,
      settings: config.settings_with_defaults
    }
  end

  def account_payload
    {
      id: account.id,
      name: account.name
    }
  end

  def user_payload
    return if user.blank?

    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end

  def conversation_payload
    conversation = find_conversation
    return if conversation.blank?

    payload = {
      id: conversation.id,
      display_id: conversation.display_id,
      status: conversation.status,
      inbox_id: conversation.inbox_id
    }
    payload[:contact] = contact_payload(conversation.contact) if send_contact_details?
    payload[:messages] = message_payloads(conversation) if send_conversation_context?
    payload
  end

  def find_conversation
    return if conversation_id.blank?

    account.conversations
           .includes(:contact, :messages)
           .find_by(id: conversation_id) ||
      account.conversations
             .includes(:contact, :messages)
             .find_by(display_id: conversation_id)
  end

  def contact_payload(contact)
    return if contact.blank?

    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      custom_attributes: contact.custom_attributes
    }
  end

  def message_payloads(conversation)
    messages = conversation.messages.reorder(created_at: :asc).last(30)
    messages.filter_map do |conversation_message|
      next if conversation_message.private? && !send_private_notes?

      {
        id: conversation_message.id,
        content: conversation_message.content,
        message_type: conversation_message.message_type,
        private: conversation_message.private?,
        sender_type: conversation_message.sender_type,
        sender_id: conversation_message.sender_id,
        created_at: conversation_message.created_at.to_i
      }
    end
  end

  def parsed_response(response)
    body = response.parsed_response
    body = JSON.parse(body) if body.is_a?(String)
    body = { 'content' => body.to_s } unless body.is_a?(Hash)

    {
      content: body['content'] || body['answer'] || body['message'],
      thread_id: body['thread_id'] || body['threadId'] || thread_id
    }
  rescue JSON::ParserError
    { content: response.body, thread_id: thread_id }
  end

  def send_conversation_context?
    config.settings_with_defaults['send_conversation_context'] == true
  end

  def send_contact_details?
    config.settings_with_defaults['send_contact_details'] == true
  end

  def send_private_notes?
    config.settings_with_defaults['send_private_notes'] == true
  end
end
