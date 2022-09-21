import User from "discourse/models/user";
import { computed } from "@ember/object";

export default {
  name: "extend-user-for-automation",
  before: "inject-discourse-objects",

  initialize() {
    User.reopen({
      add_to_mailing_list: computed("custom_fields.add_to_mailing_list", {
        get() {
          return this?.custom_fields?.add_to_mailing_list;
        },
      }),
    });
  },
};
