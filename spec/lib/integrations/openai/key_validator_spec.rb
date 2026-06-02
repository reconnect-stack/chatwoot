require 'rails_helper'

RSpec.describe Integrations::Openai::KeyValidator do
  let(:api_key) { 'sk-test-valid-key-123456789' }
  let(:probe_url) { 'https://api.openai.com/v1/models' }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
  end

  it 'accepts keys that OpenAI recognizes' do
    stub_request(:get, probe_url).to_return(status: 200)
    expect(described_class.valid?(api_key)).to be true
  end

  it 'rejects keys that OpenAI does not recognize' do
    stub_request(:get, probe_url).to_return(status: 401)
    expect(described_class.valid?(api_key)).to be false
  end

  it 'rejects blank keys without making a network call' do
    expect(described_class.valid?(nil)).to be false
    expect(described_class.valid?('')).to be false
  end

  it 'treats transient failures as valid to avoid blocking saves' do
    stub_request(:get, probe_url).to_return(status: 500)
    expect(described_class.valid?(api_key)).to be true

    stub_request(:get, probe_url).to_timeout
    expect(described_class.valid?(api_key)).to be true
  end

  it 'keeps OpenAI integration validation on the OpenAI endpoint for Chatwoot cloud' do
    set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
    set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://proxy.example.com/')
    stub_request(:get, probe_url).to_return(status: 200)

    described_class.valid?(api_key)

    expect(WebMock).to have_requested(:get, probe_url)
  end

  it 'validates against the configured OpenAI-compatible endpoint for self-hosted installs' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
    set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://proxy.example.com')
    stub_request(:get, 'https://proxy.example.com/v1/models').to_return(status: 200)

    described_class.valid?(api_key)

    expect(WebMock).to have_requested(:get, 'https://proxy.example.com/v1/models')
  end

  it 'skips remote validation for self-hosted non-OpenAI providers' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')

    expect(described_class.valid?(api_key)).to be true
    expect(WebMock).not_to have_requested(:get, probe_url)
  end
end
