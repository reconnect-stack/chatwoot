account = Account.find_by(name: 'Paper Layer') || Account.create!(name: 'Paper Layer')
widget = Channel::WebWidget.find_or_initialize_by(account: account, website_url: 'https://paperlayer.com')
widget.widget_color = '#1F7A8C'
widget.welcome_title = 'Hi there!'
widget.welcome_tagline = 'Our team can help with orders, proofs, and delivery timelines.'
widget.reply_time = :in_a_few_minutes
widget.save!
inbox = Inbox.find_or_initialize_by(account: account, channel: widget)
inbox.name = 'Paper Layer Website'
inbox.timezone = 'America/Los_Angeles'
inbox.enable_auto_assignment = false if inbox.respond_to?(:enable_auto_assignment=)
inbox.save!
agent = User.find_or_initialize_by(email: 'matthew.cruz@paperlayer.com')
agent.name = 'Matthew Cruz'
agent.password = 'Password1!'
agent.password_confirmation = 'Password1!'
agent.confirmed_at ||= Time.current if agent.respond_to?(:confirmed_at)
agent.save!
account_user = AccountUser.find_or_initialize_by(account: account, user: agent)
account_user.role = :administrator
account_user.save!
InboxMember.find_or_create_by!(inbox: inbox, user: agent) if defined?(InboxMember)
agent.update!(
  ui_settings: (agent.ui_settings || {}).merge(
    'enable_audio_alerts' => 'none',
    'notification_tone' => 'ding',
    'always_play_audio_alert' => true,
    'alert_if_unread_assigned_conversation_exist' => false,
    'is_contact_sidebar_open' => false,
    'is_conv_details_open' => false
  )
)
setting = NotificationSetting.find_or_create_by!(account: account, user: agent)
setting.selected_email_flags = []
setting.selected_push_flags = []
setting.save!
def attach_demo_avatar(record, file_path)
  return if file_path.blank? || !File.exist?(file_path)

  record.avatar.purge if record.avatar.attached?
  record.avatar.attach(io: File.open(file_path), filename: File.basename(file_path), content_type: 'image/png')
  record.avatar.representation(resize_to_fill: [250, nil]).processed if record.avatar.attached? && record.avatar.representable?
end
attach_demo_avatar(agent,
                   '/Users/vn/Documents/workspace/cw/chatwoot-skills/.agents/skills/video/chatwoot-demo-video-creator/assets/avatars/matthew-cruz.png')
def demo_company(account, name, domain)
  return nil unless defined?(Company)

  company = Company.find_or_initialize_by(account: account, domain: domain)
  company.name = name
  company.save!
  company
end
company_by_org = {
  'northstar-studio' => demo_company(account, 'Northstar Studio', 'northstarstudio.com'),
  'riverbend-retail' => demo_company(account, 'Riverbend Retail', 'riverbendretail.com'),
  'lumen-trails' => demo_company(account, 'Lumen Trails', 'lumentrails.com'),
  'atelier-nine' => demo_company(account, 'Atelier Nine', 'ateliernine.com'),
  'morning-market' => demo_company(account, 'Morning Market', 'morningmarket.com')
}
Conversation.where(account: account, inbox: inbox).where("additional_attributes ->> 'demo_key' = ?", 'notifications').destroy_all
JSON.parse('[{"name":"Emma Wilson","email":"emma@northstarstudio.com","organization":"northstar-studio","role":"Founder","avatar":"/Users/vn/Documents/workspace/cw/chatwoot-skills/.agents/skills/video/chatwoot-demo-video-creator/assets/avatars/emma-wilson.png"},{"name":"Marcus Reed","email":"marcus@riverbendretail.com","organization":"riverbend-retail","role":"Operations manager","avatar":"/Users/vn/Documents/workspace/cw/chatwoot-skills/.agents/skills/video/chatwoot-demo-video-creator/assets/avatars/marcus-reed.png"},{"name":"Daniel Kim","email":"daniel@lumentrails.com","organization":"lumen-trails","role":"Systems lead","avatar":"/Users/vn/Documents/workspace/cw/chatwoot-skills/.agents/skills/video/chatwoot-demo-video-creator/assets/avatars/daniel-kim.png"},{"name":"Sofia Patel","email":"sofia@ateliernine.com","organization":"atelier-nine","role":"Finance manager","avatar":"/Users/vn/Documents/workspace/cw/chatwoot-skills/.agents/skills/video/chatwoot-demo-video-creator/assets/avatars/sofia-patel.png"},{"name":"Priya Menon","email":"priya@morningmarket.com","organization":"morning-market","role":"Operations coordinator","avatar":"/Users/vn/Documents/workspace/cw/chatwoot-skills/.agents/skills/video/chatwoot-demo-video-creator/assets/avatars/priya-menon.png"}]').each_with_index do |persona, index|
  contact = Contact.find_or_initialize_by(account: account, email: persona['email'])
  contact.name = persona['name']
  contact.contact_type = :customer
  contact.company = company_by_org[persona['organization']] if company_by_org[persona['organization']]
  contact.additional_attributes = (contact.additional_attributes || {}).merge('role' => persona['role'])
  contact.save!
  attach_demo_avatar(contact, persona['avatar'])
  ContactInbox.where(contact: contact, inbox: inbox).where('source_id LIKE ?', 'notifications-demo-%').destroy_all
  contact_inbox = ContactInbox.create!(contact: contact, inbox: inbox, source_id: "notifications-demo-#{index}-#{Time.current.to_i}")
  conversation = Conversation.create!(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox,
                                      assignee: index.even? ? agent : nil, status: :open, additional_attributes: { demo_key: 'notifications' }, created_at: (18 - index).minutes.ago, updated_at: (18 - index).minutes.ago)
  Message.create!(account: account, inbox: inbox, conversation: conversation, sender: contact, message_type: :incoming,
                  content: ['Could you confirm the revised proof before pickup?', 'We need two more kits added to this order.', 'Can someone check the invoice status from last week?', 'The welcome cards look great. Can you send the print file?', "Could we move tomorrow's delivery to the afternoon route?"][index], created_at: (14 - index).minutes.ago, updated_at: (14 - index).minutes.ago)
  Message.create!(account: account, inbox: inbox, conversation: conversation, sender: agent, message_type: :outgoing,
                  content: ['Absolutely. I am checking it now.', 'Yes, I can help adjust the quantity.', 'Thanks, I will review the invoice shortly.', 'Glad to hear it. I will pull the file.', 'I can check the dispatch window for you.'][index], status: :sent, created_at: (12 - index).minutes.ago, updated_at: (12 - index).minutes.ago)
  conversation.update!(last_activity_at: (index + 2).minutes.ago)
end
puts({ account_id: account.id, inbox_id: inbox.id, actor: agent.email }.to_json)
