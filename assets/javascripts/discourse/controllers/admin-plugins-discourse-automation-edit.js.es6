import { set } from "@ember/object";
import { extractError } from "discourse/lib/ajax-error";
import { action } from "@ember/object";
import { reads, filterBy } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";
import discourseComputed from "discourse-common/utils/decorators";

export default Ember.Controller.extend({
  error: null,

  automation: reads("model.automation"),

  isUpdatingAutomation: false,

  scriptFields: filterBy("automationForm.fields", "target", "script"),

  triggerFields: filterBy("automationForm.fields", "target", "trigger"),

  @discourseComputed("model.automation.next_pending_automation_at")
  nextPendingAutomationAtFormatted(date) {
    if (date) {
      return moment(date).format("LLLL");
    }
  },

  @action
  saveAutomation() {
    this.setProperties({ error: null, isUpdatingAutomation: true });

    return ajax(
      `/admin/plugins/discourse-automation/automations/${this.model.automation.id}.json`,
      {
        type: "PUT",
        data: JSON.stringify({ automation: this.automationForm }),
        dataType: "json",
        contentType: "application/json"
      }
    )
      .catch(e => this.set("error", extractError(e)))
      .finally(() => {
        this.send("refreshRoute");
        this.set("isUpdatingAutomation", false);
      });
  },

  @action
  onChangeField(field, identifier, value) {
    set(field, `metadata.${identifier}`, value);
  },

  @action
  onChangeTrigger(id) {
    if (this.automationForm.trigger && this.automationForm.trigger !== id) {
      this._confirmReset(() => {
        set(this.automationForm, "trigger", id);
        this.saveAutomation();
      });
    } else if (!this.automationForm.trigger) {
      set(this.automationForm, "trigger", id);
      this.saveAutomation();
    }
  },

  @action
  onChangeScript(id) {
    if (this.automationForm.script !== id) {
      this._confirmReset(() => {
        set(this.automationForm, "script", id);
        this.saveAutomation();
      });
    }
  },

  _confirmReset(callback) {
    bootbox.confirm(
      I18n.t("discourse_automation.confirm_automation_reset"),
      I18n.t("no_value"),
      I18n.t("yes_value"),
      result => {
        if (result) {
          callback && callback();
        }
      }
    );
  }
});
