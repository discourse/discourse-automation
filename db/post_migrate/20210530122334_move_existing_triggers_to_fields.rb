# frozen_string_literal: true

class MoveExistingTriggersToFields < ActiveRecord::Migration[6.1]
  def create_field(automation, component, name, metadata)
    DB.exec(<<~SQL, automation_id: automation.id, component: component, name: name, metadata: metadata.to_json, created_at: Time.zone.now)
      INSERT INTO discourse_automation_fields (automation_id, component, name, metadata, target, created_at, updated_at)
      VALUES (:automation_id, :component, :name, :metadata, 'trigger', :created_at, :created_at)
    SQL
  end

  def change
    DB.query('SELECT name,automation_id,metadata FROM discourse_automation_triggers').each do |trigger|
      automation = DiscourseAutomation::Automation.find(trigger.automation_id)

      if trigger.name == 'point-in-time'
        trigger.name = 'point_in_time'
      end

      automation.update_column(:trigger, trigger.name)

      trigger.metadata.each do |key, value|
        if key == 'group_ids' && trigger.name == 'user_added_to_group'
          create_field(automation, 'group', 'joined_group', { group_id: value })
        end

        if key == 'execute_at' && trigger.name == 'point-in-time'
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
