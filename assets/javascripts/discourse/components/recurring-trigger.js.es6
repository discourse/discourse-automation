import Component from "@ember/component";

export default Component.extend({
  actions: {
    yolo() {
      this.set("metadata.recurrence", "every_week");
    }
  }
});
