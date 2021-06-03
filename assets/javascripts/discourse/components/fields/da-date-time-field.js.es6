import Component from "@ember/component";
import { action, computed } from "@ember/object";

export default Component.extend({
  tagName: "",

  @action
  convertToUniversalTime(date) {
    return (
      date &&
      this.set(
        "field.metadata.value",
        moment(date)
          .utc()
          .format()
      )
    );
  },

  localTime: computed("field.metadata.value", function() {
    return (
      this.field.metadata.value &&
      moment(this.field.metadata.value)
        .local()
        .format(moment.HTML5_FMT.DATETIME_LOCAL)
    );
  })
});
