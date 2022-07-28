# frozen_string_literal: true

# name: discourse-automation
# about: Lets you automate actions on your Discourse Forum
# version: 0.1
# authors: jjaffeux
# url: https://github.com/discourse/discourse-automation
# transpile_js: true

gem 'iso8601', '0.13.0'
gem 'rrule', '0.4.4'

register_asset 'stylesheets/common/discourse-automation.scss'
enabled_site_setting :discourse_automation_enabled

PLUGIN_NAME ||= 'discourse-automation'

def handle_post_created_edited(post, action)
  return if post.post_type != Post.types[:regular] || post.user_id < 0

  name = DiscourseAutomation::Triggerable::POST_CREATED_EDITED

  DiscourseAutomation::Automation
    .where(trigger: name, enabled: true)
    .find_each do |automation|
      valid_trust_levels = automation.trigger_field('valid_trust_levels')
      if valid_trust_levels['value']
        next unless valid_trust_levels['value'].include?(post.user.trust_level)
      end

      restricted_category = automation.trigger_field('restricted_category')
      if restricted_category['value']
        category_id = post.topic&.category&.parent_category&.id || post.topic&.category&.id
        next if restricted_category['value'] != category_id
      end

      automation.trigger!('kind' => name, 'action' => action, 'post' => post)
    end
end

def handle_pm_created(topic)
  return if topic.user_id < 0

  user = topic.user
  target_usernames = topic.allowed_users.pluck(:username) - [user.username]
  return unless target_usernames.count == 1

  name = DiscourseAutomation::Triggerable::PM_CREATED

  DiscourseAutomation::Automation
    .where(trigger: name, enabled: true)
    .find_each do |automation|

      restricted_username = automation.trigger_field('restricted_user')['value']
      next if restricted_username != target_usernames.first

      ignore_staff = automation.trigger_field('ignore_staff')
      next if ignore_staff['value'] && user.staff?

      valid_trust_levels = automation.trigger_field('valid_trust_levels')
      if valid_trust_levels['value']
        next unless valid_trust_levels['value'].include?(user.trust_level)
      end

      automation.trigger!('kind' => name, 'post' => topic.first_post)
    end
end

def handle_after_post_cook(post, cooked)
  return cooked if post.post_type != Post.types[:regular] || post.post_number > 1

  name = DiscourseAutomation::Triggerable::AFTER_POST_COOK

  DiscourseAutomation::Automation
    .where(trigger: name, enabled: true)
    .find_each do |automation|
      valid_trust_levels = automation.trigger_field('valid_trust_levels')
      if valid_trust_levels['value']
        next unless valid_trust_levels['value'].include?(post.user.trust_level)
      end

      restricted_category = automation.trigger_field('restricted_category')
      if restricted_category['value']
        category_id = post.topic&.category&.parent_category&.id || post.topic&.category&.id
        next if restricted_category['value'] != category_id
      end

      if new_cooked = automation.trigger!('kind' => name, 'post' => post, 'cooked' => cooked)
        cooked = new_cooked
      end
    end

  cooked
end

def handle_user_promoted(user_id, new_trust_level, old_trust_level)
  trigger = DiscourseAutomation::Triggerable::USER_PROMOTED
  user = User.find_by(id: user_id)
  return if user.blank?

  # don't want to do anything if the user is demoted. this should probably
  # be a separate event in core
  return if new_trust_level < old_trust_level

  DiscourseAutomation::Automation.where(trigger: trigger, enabled: true).find_each do |automation|
    trust_level_code_all = DiscourseAutomation::Triggerable::USER_PROMOTED_TRUST_LEVEL_CHOICES.first[:id]

    restricted_group_id = automation.trigger_field('restricted_group')['value']
    trust_level_transition = automation.trigger_field('trust_level_transition')['value']
    trust_level_transition = trust_level_transition || trust_level_code_all

    next if restricted_group_id.present? && !GroupUser.exists?(user_id: user_id, group_id: restricted_group_id)

    transition_code = "TL#{old_trust_level}#{new_trust_level}"
    if trust_level_transition == trust_level_code_all || trust_level_transition == transition_code
      automation.trigger!(
        'kind' => trigger,
        'usernames' => [user.username],
        'placeholders' => {
          'trust_level_transition' => I18n.t(
            "discourse_automation.triggerables.user_promoted.transition_placeholder",
            from_level_name: TrustLevel.name(old_trust_level),
            to_level_name: TrustLevel.name(new_trust_level)
          )
        }
      )
    end
  end
end

require File.expand_path('../app/lib/discourse_automation/triggerable', __FILE__)
require File.expand_path('../app/lib/discourse_automation/scriptable', __FILE__)
require File.expand_path('../app/core_ext/plugin_instance', __FILE__)

after_initialize do
  [
    '../app/queries/stalled_topic_finder',
    '../app/services/discourse_automation/user_badge_granted_handler',
    '../app/lib/discourse_automation/triggers/after_post_cook',
    '../app/lib/discourse_automation/triggers/stalled_wiki',
    '../app/lib/discourse_automation/triggers/stalled_topic',
    '../app/lib/discourse_automation/triggers/user_added_to_group',
    '../app/lib/discourse_automation/triggers/user_badge_granted',
    '../app/lib/discourse_automation/triggers/pm_created',
    '../app/lib/discourse_automation/triggers/point_in_time',
    '../app/lib/discourse_automation/triggers/post_created_edited',
    '../app/lib/discourse_automation/triggers/topic',
    '../app/lib/discourse_automation/triggers/api_call',
    '../app/controllers/discourse_automation/append_last_checked_by_controller',
    '../app/controllers/discourse_automation/automations_controller',
    '../app/controllers/discourse_automation/user_global_notices_controller',
    '../app/controllers/admin/discourse_automation/admin_discourse_automation_controller',
    '../app/controllers/admin/discourse_automation/admin_discourse_automation_automations_controller',
    '../app/controllers/admin/discourse_automation/admin_discourse_automation_scriptables_controller',
    '../app/controllers/admin/discourse_automation/admin_discourse_automation_triggerables_controller',
    '../app/serializers/discourse_automation/automation_serializer',
    '../app/serializers/discourse_automation/template_serializer',
    '../app/serializers/discourse_automation/automation_field_serializer',
    '../app/serializers/discourse_automation/trigger_serializer',
    '../app/serializers/discourse_automation/user_global_notice_serializer',
    '../app/models/discourse_automation/automation',
    '../app/models/discourse_automation/pending_automation',
    '../app/models/discourse_automation/pending_pm',
    '../app/models/discourse_automation/user_global_notice',
    '../app/models/discourse_automation/field',
    '../app/jobs/regular/call_zapier_webhook',
    '../app/jobs/scheduled/discourse_automation_tracker',
    '../app/jobs/scheduled/stalled_wiki_tracker',
    '../app/jobs/scheduled/stalled_topic_tracker',
    '../app/lib/discourse_automation/triggers/recurring',
    '../app/lib/discourse_automation/triggers/user_promoted',
    '../app/lib/discourse_automation/scripts/append_last_checked_by',
    '../app/lib/discourse_automation/scripts/append_last_edited_by',
    '../app/lib/discourse_automation/scripts/auto_responder',
    '../app/lib/discourse_automation/scripts/banner_topic',
    '../app/lib/discourse_automation/scripts/suspend_user_by_email',
    '../app/lib/discourse_automation/scripts/close_topic',
    '../app/lib/discourse_automation/scripts/pin_topic',
    '../app/lib/discourse_automation/scripts/user_global_notice',
    '../app/lib/discourse_automation/scripts/gift_exchange',
    '../app/lib/discourse_automation/scripts/send_pms',
    '../app/lib/discourse_automation/scripts/topic_required_words',
    '../app/lib/discourse_automation/scripts/flag_post_on_words',
    '../app/lib/discourse_automation/scripts/zapier_webhook',
  ].each { |path| require File.expand_path(path, __FILE__) }

  module ::DiscourseAutomation
    CUSTOM_FIELD ||= 'discourse_automation_ids'
    TOPIC_LAST_CHECKED_BY ||= 'discourse_automation_last_checked_by'
    TOPIC_LAST_CHECKED_AT ||= 'discourse_automation_last_checked_at'

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseAutomation
    end
  end

  add_admin_route 'discourse_automation.title', 'discourse-automation'

  add_api_key_scope(:automations_trigger, { post: { actions: %w[discourse_automation/automations#trigger], params: %i[context], formats: :json } })

  add_to_serializer(:current_user, :global_notices) do
    notices = DiscourseAutomation::UserGlobalNotice.where(user_id: object.id)
    ActiveModel::ArraySerializer.new(
      notices,
      each_serializer: DiscourseAutomation::UserGlobalNoticeSerializer
    ).as_json
  end

  DiscourseAutomation::Engine.routes.draw do
    scope format: :json, constraints: AdminConstraint.new do
      post '/automations/:id/trigger' => 'automations#trigger'
    end

    scope format: :json do
      delete '/user-global-notices/:id' => 'user_global_notices#destroy'
      put '/append-last-checked-by/:post_id' => 'append_last_checked_by#post_checked'
    end

    scope '/admin/plugins/discourse-automation', as: 'admin_discourse_automation', constraints: AdminConstraint.new do
      scope format: false do
        get '/' => 'admin_discourse_automation#index'
        get '/new' => 'admin_discourse_automation#new'
        get '/:id' => 'admin_discourse_automation#edit'
      end

      scope format: :json do
        get '/scriptables' => 'admin_discourse_automation_scriptables#index'
        get '/triggerables' => 'admin_discourse_automation_triggerables#index'
        get '/automations' => 'admin_discourse_automation_automations#index'
        get '/automations/:id' => 'admin_discourse_automation_automations#show'
        delete '/automations/:id' => 'admin_discourse_automation_automations#destroy'
        put '/automations/:id' => 'admin_discourse_automation_automations#update'
        post '/automations' => 'admin_discourse_automation_automations#create'
      end
    end
  end

  Discourse::Application.routes.append do
    mount ::DiscourseAutomation::Engine, at: '/'
  end

  on(:user_added_to_group) do |user, group|
    name = DiscourseAutomation::Triggerable::USER_ADDED_TO_GROUP

    DiscourseAutomation::Automation.where(trigger: name, enabled: true).find_each do |automation|
      joined_group = automation.trigger_field('joined_group')
      if joined_group['value'] == group.id
        automation.trigger!(
          'kind' => DiscourseAutomation::Triggerable::USER_ADDED_TO_GROUP,
          'usernames' => [user.username],
          'group' => group,
          'placeholders' => {
            'group_name' => group.name
          }
        )
      end
    end
  end

  on(:user_badge_granted) do |badge_id, user_id|
    name = DiscourseAutomation::Triggerable::USER_BADGE_GRANTED
    DiscourseAutomation::Automation
      .where(trigger: name, enabled: true)
      .find_each do |automation|
        DiscourseAutomation::UserBadgeGrantedHandler.handle(automation, badge_id, user_id)
      end
  end

  on(:user_promoted) do |payload|
    user_id, new_trust_level, old_trust_level = payload.values_at(:user_id, :new_trust_level, :old_trust_level)
    handle_user_promoted(user_id, new_trust_level, old_trust_level)
  end

  on(:topic_created) do |topic|
    handle_pm_created(topic) if topic.private_message?
  end

  on(:post_created) do |post|
    handle_post_created_edited(post, :create)
  end

  on(:post_edited) do |post|
    handle_post_created_edited(post, :edit)
  end

  Plugin::Filter.register(:after_post_cook) do |post, cooked|
    handle_after_post_cook(post, cooked)
  end

  register_topic_custom_field_type(DiscourseAutomation::CUSTOM_FIELD, [:integer])
  register_user_custom_field_type(DiscourseAutomation::CUSTOM_FIELD, [:integer])
  register_post_custom_field_type(DiscourseAutomation::CUSTOM_FIELD, [:integer])
  register_post_custom_field_type('stalled_wiki_triggered_at', :string)

  reloadable_patch do
    require 'post'

    class ::Post
      validate :discourse_automation_topic_required_words

      def discourse_automation_topic_required_words
        return if !SiteSetting.discourse_automation_enabled
        return if self.post_type == Post.types[:small_action]
        return if !topic
        return if topic.custom_fields[DiscourseAutomation::CUSTOM_FIELD].blank?

        topic.custom_fields[DiscourseAutomation::CUSTOM_FIELD].each do |automation_id|
          automation = DiscourseAutomation::Automation.find_by(id: automation_id)
          next if automation&.script != DiscourseAutomation::Scriptable::TOPIC_REQUIRED_WORDS

          words = automation.fields.find_by(name: 'words')&.metadata['value']
          next if words.blank?

          if words.none? { |word| raw.include?(word) }
            errors.add(:base, I18n.t('discourse_automation.scriptables.topic_required_words.errors.must_include_word', words: words.join(', ')))
          end
        end
      end
    end
  end
end

Rake::Task.define_task run_automation: :environment do
  script_methods = DiscourseAutomation::Scriptable.all

  scripts = []

  DiscourseAutomation::Automation.find_each do |automation|
    script_methods.each do |name|
      type = name.to_s.gsub('script_', '')

      next if type != automation.script

      scriptable = automation.scriptable
      scriptable.public_send(name)
      scripts << scriptable.script.call
    end
  end
end
