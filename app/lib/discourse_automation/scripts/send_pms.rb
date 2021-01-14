# frozen_string_literal: true

DiscourseAutomation::Scriptable.add('send_pms') do
  version 1

  placeholder :sender_username
  placeholder :receiver_username

  field :sender, component: :user
  field :sendable_pms, component: :pms, accepts_placeholders: true

  triggerables %i[user_added_to_group]

  script do |trigger, fields|
    placeholders = {
      receiver_username: trigger['user'].username,
      sender_username: fields['sender']['username']
    }

    fields['sendable_pms']['pms'].each do |pm|
      pm['title'] = utils.apply_placeholders(pm['title'], placeholders)
      pm['raw'] = utils.apply_placeholders(pm['raw'], placeholders)
      pm['automation_id'] = automation.id
      pm['target_usernames'] = Array(trigger['user'].username)
      utils.send_pm(pm, User.find_by(username: fields['sender']['username']))
    end
  end
end
