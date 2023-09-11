import Component from "@ember/component";
import { computed } from "@ember/object";
import I18n from "I18n";

export default class AutomationField extends Component {
  tagName = "";
  field = null;
  automation = null;
  saveAutomation = null;

  @computed("automation.trigger.id", "field.triggerable")
  get displayField() {
    const triggerId = this.automation?.trigger?.id;
    const triggerable = this.field?.triggerable;
    return triggerId && (!triggerable || triggerable === triggerId);
  }

  @computed("field.placeholders")
  get placeholdersString() {
    return this.field.placeholders.join(", ");
  }

  @computed("field.target")
  get target() {
    return this.field.target === "script"
      ? `.scriptables.${this.automation.script.id.replace(/-/g, "_")}.`
      : `.triggerables.${this.automation.trigger.id.replace(/-/g, "_")}.`;
  }

  @computed("target", "field.name")
  get translationKey() {
    return `discourse_automation${this.target}fields.${this.field.name}.description`;
  }

  @computed("translationKey")
  get description() {
    return I18n.lookup(this.translationKey);
  }
}
