class CreateCaptainExternalAssistantConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :captain_external_assistant_configs do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.string :service_url
      t.text :access_token
      t.string :assistant_id
      t.jsonb :settings, null: false, default: {}
      t.datetime :last_verified_at
      t.text :last_error

      t.timestamps
    end
  end
end
