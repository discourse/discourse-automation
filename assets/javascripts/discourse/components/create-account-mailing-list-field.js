import Component from "@ember/component";
import { action } from "@ember/object";
import { getOwner } from "discourse-common/lib/get-owner";

export default Component.extend({
  controller: getOwner(this).lookup("controller:create-account"),

  @action
  onChangeMailingSetting(value) {
    this.controller.customFields[
      `add_to_mailing_list_${this.automation.list_id}`
    ] = value;
  },
});
