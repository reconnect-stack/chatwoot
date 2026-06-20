# == Schema Information
#
# Table name: captain_copilot_message_feedbacks
#
#  id                 :bigint           not null, primary key
#  assistant_id       :string
#  copilot_message_id :string           not null
#  copilot_thread_id  :string           not null
#  rating             :string           not null
#  trace_id           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  conversation_id    :bigint
#  user_id            :bigint           not null
#
# Indexes
#
#  index_captain_copilot_message_feedbacks_on_account_id  (account_id)
#  index_captain_copilot_message_feedbacks_on_user_id     (user_id)
#  index_copilot_message_feedbacks_on_scope               (account_id,copilot_thread_id,copilot_message_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class Captain::CopilotMessageFeedback < ApplicationRecord
  self.table_name = 'captain_copilot_message_feedbacks'

  RATINGS = %w[up down].freeze

  belongs_to :account
  belongs_to :user

  validates :copilot_thread_id, presence: true
  validates :copilot_message_id, presence: true
  validates :rating, presence: true, inclusion: { in: RATINGS }
end
