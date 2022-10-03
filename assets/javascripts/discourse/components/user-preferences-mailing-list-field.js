import Component from "@ember/component";
import { action } from "@ember/object";

export default Component.extend({
  @action
  onChangeMailingSetting(value) {
    this.set(
      `model.custom_fields.add_to_mailing_list_${this.automation.list_id}`,
      value
    );
  },

  value() {
    return this.get(
      `model.custom_fields.add_to_mailing_list_${this.automation.list_id}`
    );
  },
});
