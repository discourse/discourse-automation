import Component from "@ember/component";
import I18n from "I18n";
import { computed } from "@ember/object";

export default Component.extend({
  tagName: "",
  key: null,
  options: null,

  lookup: computed("key", "options", function() {
    return I18n.lookup(
      this.key,
      Object.assign({}, this.options || {}, { locale: I18n.locale })
    );
  }),

  options: computed("attrs", function() {
    const options = this.attrs;
    delete options.key;
    return options;
  })
}).reopenClass({
  positionalParams: ["key"]
});
