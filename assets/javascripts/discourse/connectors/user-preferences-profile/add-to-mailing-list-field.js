import { action } from "@ember/object";
import { getOwner } from "discourse-common/lib/get-owner";

export default {
  @action
  onChangeMailingSetting(value) {
    this.set("model.custom_fields.add_to_mailing_list", value);
  },
};
