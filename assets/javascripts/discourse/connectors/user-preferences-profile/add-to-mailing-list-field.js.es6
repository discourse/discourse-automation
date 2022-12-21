import { action } from "@ember/object";
import { getOwner } from "discourse-common/lib/get-owner";
import { get } from "jquery";

export default {
  @action
  onChangeMailingSetting(automation, pointerEvent) {
    this.set(`model.custom_fields.add_to_mailing_list_${automation.list_id}`, pointerEvent.target.value);
  },
};
