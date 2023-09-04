# frozen_string_literal: true

module DiscourseAutomation
  module EventHandlers
    def self.handle_post_created_edited(post, action)
      return if post.post_type != Post.types[:regular] || post.user_id < 0
      topic = post.topic
      return if topic.blank?

      name = DiscourseAutomation::Triggerable::POST_CREATED_EDITED

      DiscourseAutomation::Automation
        .where(trigger: name, enabled: true)
        .find_each do |automation|
          valid_trust_levels = automation.trigger_field("valid_trust_levels")
          if valid_trust_levels["value"]
            next unless valid_trust_levels["value"].include?(post.user.trust_level)
          end

          restricted_category = automation.trigger_field("restricted_category")
          if restricted_category["value"]
            category_ids =
              if topic.category_id.blank?
                []
              else
                [topic.category_id, topic.category.parent_category_id]
              end
            next if !category_ids.include?(restricted_category["value"])
          end

          if topic.private_message?
            target_group_ids = topic.allowed_groups.pluck(:id)
            restricted_group_id = automation.trigger_field("restricted_group")["value"]
            next if restricted_group_id.present? && restricted_group_id != target_group_ids.first

            ignore_group_members = automation.trigger_field("ignore_group_members")
            next if ignore_group_members["value"] && post.user.in_any_groups?([restricted_group_id])
          end

          ignore_automated = automation.trigger_field("ignore_automated")
          next if ignore_automated["value"] && post.incoming_email&.is_auto_generated?

          action_type = automation.trigger_field("action_type")
          selected_action = action_type["value"]&.to_sym

          if selected_action
            next if selected_action == :created && action != :create
            next if selected_action == :edited && action != :edit
          end
          automation.trigger!("kind" => name, "action" => action, "post" => post)
        end
    end

    def self.handle_category_created_edited(category, action)
      name = DiscourseAutomation::Triggerable::CATEGORY_CREATED_EDITED

      DiscourseAutomation::Automation
        .where(trigger: name, enabled: true)
        .find_each do |automation|
          restricted_category = automation.trigger_field("restricted_category")
          if restricted_category["value"].present?
            next if restricted_category["value"] != category.parent_category_id
          end

          automation.trigger!("kind" => name, "action" => action, "category" => category)
        end
    end

    def self.handle_pm_created(topic)
      return if topic.user_id < 0

      user = topic.user
      target_usernames = topic.allowed_users.pluck(:username) - [user.username]
      target_group_ids = topic.allowed_groups.pluck(:id)
      return if (target_usernames.length + target_group_ids.length) > 1

      name = DiscourseAutomation::Triggerable::PM_CREATED

      DiscourseAutomation::Automation
        .where(trigger: name, enabled: true)
        .find_each do |automation|
          restricted_username = automation.trigger_field("restricted_user")["value"]
          next if restricted_username.present? && restricted_username != target_usernames.first

          restricted_group_id = automation.trigger_field("restricted_group")["value"]
          next if restricted_group_id.present? && restricted_group_id != target_group_ids.first

          ignore_staff = automation.trigger_field("ignore_staff")
          next if ignore_staff["value"] && user.staff?

          ignore_group_members = automation.trigger_field("ignore_group_members")
          next if ignore_group_members["value"] && user.in_any_groups?([restricted_group_id])

          ignore_automated = automation.trigger_field("ignore_automated")
          next if ignore_automated["value"] && topic.first_post.incoming_email&.is_auto_generated?

          valid_trust_levels = automation.trigger_field("valid_trust_levels")
          if valid_trust_levels["value"]
            next if !valid_trust_levels["value"].include?(user.trust_level)
          end

          automation.trigger!("kind" => name, "post" => topic.first_post)
        end
    end

    def self.handle_after_post_cook(post, cooked)
      return cooked if post.post_type != Post.types[:regular] || post.post_number > 1

      name = DiscourseAutomation::Triggerable::AFTER_POST_COOK

      DiscourseAutomation::Automation
        .where(trigger: name, enabled: true)
        .find_each do |automation|
          valid_trust_levels = automation.trigger_field("valid_trust_levels")
          if valid_trust_levels["value"]
            next unless valid_trust_levels["value"].include?(post.user.trust_level)
          end

          restricted_category = automation.trigger_field("restricted_category")
          if restricted_category["value"]
            category_ids = [post.topic&.category&.parent_category&.id, post.topic&.category&.id]
            next if !category_ids.compact.include?(restricted_category["value"])
          end

          restricted_tags = automation.trigger_field("restricted_tags")
          if tag_names = restricted_tags["value"]
            found = false
            next if !post.topic

            post.topic.tags.each do |tag|
              found ||= tag_names.include?(tag.name)
              break if found
            end

            next if !found
          end

          if new_cooked = automation.trigger!("kind" => name, "post" => post, "cooked" => cooked)
            cooked = new_cooked
          end
        end

      cooked
    end

    def self.handle_user_promoted(user_id, new_trust_level, old_trust_level)
      trigger = DiscourseAutomation::Triggerable::USER_PROMOTED
      user = User.find_by(id: user_id)
      return if user.blank?

      # don't want to do anything if the user is demoted. this should probably
      # be a separate event in core
      return if new_trust_level < old_trust_level

      DiscourseAutomation::Automation
        .where(trigger: trigger, enabled: true)
        .find_each do |automation|
          trust_level_code_all =
            DiscourseAutomation::Triggerable::USER_PROMOTED_TRUST_LEVEL_CHOICES.first[:id]

          restricted_group_id = automation.trigger_field("restricted_group")["value"]
          trust_level_transition = automation.trigger_field("trust_level_transition")["value"]
          trust_level_transition = trust_level_transition || trust_level_code_all

          if restricted_group_id.present? &&
               !GroupUser.exists?(user_id: user_id, group_id: restricted_group_id)
            next
          end

          transition_code = "TL#{old_trust_level}#{new_trust_level}"
          if trust_level_transition == trust_level_code_all ||
               trust_level_transition == transition_code
            automation.trigger!(
              "kind" => trigger,
              "usernames" => [user.username],
              "placeholders" => {
                "trust_level_transition" =>
                  I18n.t(
                    "discourse_automation.triggerables.user_promoted.transition_placeholder",
                    from_level_name: TrustLevel.name(old_trust_level),
                    to_level_name: TrustLevel.name(new_trust_level),
                  ),
              },
            )
          end
        end
    end

    def self.handle_stalled_topic(post)
      return if post.topic.blank?
      return if post.user_id != post.topic.user_id

      DiscourseAutomation::Automation
        .where(trigger: DiscourseAutomation::Triggerable::STALLED_TOPIC)
        .where(enabled: true)
        .find_each do |automation|
          fields = automation.serialized_fields

          categories = fields.dig("categories", "value")
          next if categories && !categories.include?(post.topic.category_id)

          tags = fields.dig("tags", "value")
          next if tags && (tags & post.topic.tags.map(&:name)).empty?

          DiscourseAutomation::UserGlobalNotice
            .where(identifier: automation.id)
            .where(user_id: post.user_id)
            .destroy_all
        end
    end
  end
end
