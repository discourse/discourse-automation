import { set } from "@ember/object";
import { extractError } from "discourse/lib/ajax-error";
import { action, computed } from "@ember/object";
import { reads } from "@ember/object/computed";

export default Ember.Controller.extend({
  error: null,

  automation: reads("model.automation"),

  isUpdatingAutomation: false,

  triggerComponentName: computed("automation.trigger.name", function() {
    return (
      "triggers/" + this.automation.trigger.name.replace(/_/, "-") + "-trigger"
    );
  }),

  @action
  saveAutomation(automation) {
    this.setProperties({ error: null, isUpdatingAutomation: true });

    return automation
      .update()
      .catch(e => this.set("error", extractError(e)))
      .finally(() => this.set("isUpdatingAutomation", false));
  },

  @action
  onChangeField(field, identifier, value) {
    set(field, `metadata.${identifier}`, value);
  },

  @action
  onChangeTrigger(name) {
    set(this.model.automation.trigger, "name", name);
    return this.saveAutomation(this.automation);
  }
});
