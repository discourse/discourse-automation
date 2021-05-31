# frozen_string_literal: true

module DiscourseAutomation
  class Field < ActiveRecord::Base
    self.table_name = 'discourse_automation_fields'

    belongs_to :automation, class_name: 'DiscourseAutomation::Automation'

    around_save :on_update_callback

    def on_update_callback
      previous_fields = automation.serialized_fields

      automation.reset!

      yield

      DiscourseAutomation::Triggerable.new(automation.trigger).on_update.call(
        automation,
        automation.serialized_fields,
        previous_fields
      )
    end

    SCHEMAS = {
      'category' => {
        'category_id' => {
          'type' => 'integer'
        }
      },
      'user' => {
        'username' => {
          'type' => 'string'
        }
      },
      'text' => {
        'text' => {
          'type' => 'string'
        }
      },
      'text_list' => {
        'list' => {
          'type' => 'array',
          'items' => [{ 'type': 'string' }]
        }
      },
      'date' => {
        'execute_at' => {
          'type' => 'integer'
        }
      },
      'group' => {
        'group_id' => {
          'type' => 'integer'
        }
      },
      'pms' => {
        'type': 'array',
        'items': [
          {
            'type': 'object',
            'properties': {
              'raw' => { 'type' => 'string' },
              'title' => { 'type' => 'string' },
              'delay' => { 'type' => 'integer' },
              'encrypt' => { 'type' => 'boolean' }
            }
          }
        ]
      }
    }
  end
end
