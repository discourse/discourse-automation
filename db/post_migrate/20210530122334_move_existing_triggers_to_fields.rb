# frozen_string_literal: true

class MoveExistingTriggersToFields < ActiveRecord::Migration[6.1]
  def create_field(automation, component, name, metadata)
    automation.fields.create!(
      component: component,
      name: name,
      metadata: metadata,
      target: 'trigger'
    )
  end

  def change
    DB.query('SELECT name,automation_id,metadata FROM discourse_automation_triggers').each do |trigger|
      automation = DiscourseAutomation::Automation.find(trigger.automation_id)

      automation.update_column(:trigger, trigger.name)

      trigger.metadata.each do |key, value|
        if key == 'group_ids' && trigger.name == 'user_added_to_group'
          create_field(automation, 'group', 'joined_group', { group_id: value })
        end

        if key == 'execute_at' && trigger.name == 'point_in_time'
          create_field(automation, 'date', 'execute_at', { date: value })
        end

        if key == 'category_id' && trigger.name == 'post_created_edited'
          create_field(automation, 'category', 'restricted_category', { category_id: value })
        end

        if key == 'topic' && trigger.name == 'topic'
          create_field(automation, 'topic', 'restricted_topic', { topic_id: value })
        end
      end
    end

    execute <<~SQL
      ALTER TABLE discourse_automation_automations ALTER COLUMN trigger SET NOT NULL;
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS discourse_automation_triggers;
    SQL
  end
end
