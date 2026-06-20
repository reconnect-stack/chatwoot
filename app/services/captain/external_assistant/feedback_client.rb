class Captain::ExternalAssistant::FeedbackClient
  pattr_initialize [
    :config!,
    :trace_id!,
    :rating!,
    :user,
    :thread_id,
    :conversation_id
  ]

  def perform
    response = HTTParty.post(
      config.feedback_endpoint_url,
      headers: headers,
      body: payload.to_json,
      timeout: 30
    )

    raise Captain::ExternalAssistant::Error, response.body unless response.success?

    true
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
      trace_id: trace_id,
      value: rating,
      kind: 'explicit',
      operator_id: user&.id&.to_s,
      thread_id: thread_id,
      conversation_id: conversation_id
    }.compact
  end
end
