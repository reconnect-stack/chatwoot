# == Schema Information
#
# Table name: captain_external_assistant_configs
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  enabled          :boolean          default(FALSE), not null
#  last_error       :text
#  last_verified_at :datetime
#  service_url      :string
#  settings         :jsonb            not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  assistant_id     :string
#
# Indexes
#
#  index_captain_external_assistant_configs_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Captain::ExternalAssistantConfig < ApplicationRecord
  self.table_name = 'captain_external_assistant_configs'

  DEFAULT_SETTINGS = {
    'send_conversation_context' => true,
    'send_contact_details' => true,
    'send_private_notes' => false
  }.freeze

  belongs_to :account

  encrypts :access_token if Chatwoot.encryption_configured?

  validates :service_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :service_url, presence: true, if: :enabled?

  before_validation :apply_default_settings

  def settings_with_defaults
    DEFAULT_SETTINGS.merge(settings || {})
  end

  private

  def apply_default_settings
    self.settings = settings_with_defaults
  end
end
