module Integrations::Openai::KeyValidator
  TIMEOUT_SECONDS = 5

  def self.valid?(api_key)
    return false if api_key.blank?
    return true if skip_remote_validation?

    connection = Faraday.new do |f|
      f.options.timeout = TIMEOUT_SECONDS
      f.options.open_timeout = TIMEOUT_SECONDS
    end

    response = connection.get("#{api_base}/models") do |req|
      req.headers['Authorization'] = "Bearer #{api_key}"
    end

    response.status != 401
  rescue Faraday::Error => e
    Rails.logger.warn("[openai-key-validator] #{e.class}: #{e.message}")
    true
  end

  def self.api_base
    return Llm::OpenAiConfig.api_v1_base if ChatwootApp.chatwoot_cloud?

    Llm::Config.api_base_for(provider: Llm::Config::DEFAULT_PROVIDER) || Llm::OpenAiConfig.api_v1_base
  end

  def self.skip_remote_validation?
    !ChatwootApp.chatwoot_cloud? && Llm::Config.default_provider != Llm::Config::DEFAULT_PROVIDER
  end
end
