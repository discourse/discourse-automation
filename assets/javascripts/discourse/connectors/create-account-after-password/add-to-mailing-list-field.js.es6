import { action } from "@ember/object";
import { getOwner } from "discourse-common/lib/get-owner";

export default {
  @action
  onChangeMailingSetting(value) {
    getOwner(this).lookup("controller:create-account").addToMailingList = value;
  },
};
