class CreateCaptainCopilotMessageFeedbacks < ActiveRecord::Migration[7.0]
  def change
    create_table :captain_copilot_message_feedbacks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :copilot_thread_id, null: false
      t.string :copilot_message_id, null: false
      t.string :trace_id
      t.string :rating, null: false
      t.bigint :conversation_id
      t.string :assistant_id

      t.timestamps
    end

    add_index :captain_copilot_message_feedbacks,
              %i[account_id copilot_thread_id copilot_message_id user_id],
              unique: true,
              name: 'index_copilot_message_feedbacks_on_scope'
  end
end
