# frozen_string_literal: true

DiscourseAutomation::Triggerable::MAILING_LIST = 'mailing_list'

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::MAILING_LIST) do
  on_update do |automation, metadata, previous_metadata|
    list_id = metadata.dig('list_id', 'value')

    return unless list_id

    custom_field = "add_to_mailing_list_#{list_id}"

    unless DiscoursePluginRegistry.self_editable_user_custom_fields.include?(custom_field)
      path = "#{Rails.root}/plugins/discourse-automation/plugin.rb"
      source = File.read(path)
      metadata = Plugin::Metadata.parse(source)
      plugin_instance = Plugin::Instance.new(metadata, path)

      DiscoursePluginRegistry.register_self_editable_user_custom_field(custom_field, plugin_instance)
      User.register_custom_field_type(custom_field, :boolean)
      DiscoursePluginRegistry.register_public_user_custom_field(custom_field, plugin_instance)
    end
  end
end
