import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import ModalJsonSchemaEditor from "discourse/components/modal/json-schema-editor";
import I18n from "I18n";
import BaseField from "./da-base-field";
import DAFieldDescription from "./da-field-description";
import DAFieldLabel from "./da-field-label";

export default class KeyValueField extends BaseField {
  @tracked showJsonEditorModal = false;

  jsonSchema = {
    type: "array",
    uniqueItems: true,
    items: {
      type: "object",
      title: "group",
      properties: {
        key: {
          type: "string",
        },
        value: {
          type: "string",
          format: "textarea",
        },
      },
    },
  };

  <template>
    <section class="field key-value-field">
      <div class="control-group">
        <DAFieldLabel @label={{@label}} @field={{@field}} />

        <div class="controls">
          <DButton class="configure-btn" @action={{this.openModal}}>
            {{this.showJsonModalLabel}}
          </DButton>

          {{#if this.showJsonEditorModal}}
            <ModalJsonSchemaEditor
              @updateValue={{this.handleValueChange}}
              @value={{this.value}}
              @settingName={{@label}}
              @jsonSchema={{this.jsonSchema}}
              @closeModal={{this.closeModal}}
            />
          {{/if}}

          <DAFieldDescription @description={{@description}} />
        </div>
      </div>
    </section>
  </template>

  get value() {
    return (
      this.args.field.metadata.value ||
      '[{"key":"example","value":"You posted %%KEY%%"}]'
    );
  }

  get keyCount() {
    if (this.args.field.metadata.value) {
      return JSON.parse(this.value).length;
    }

    return 0;
  }

  get showJsonModalLabel() {
    return I18n.t("discourse_automation.fields.key_value.label", {
      count: this.keyCount,
    });
  }

  @action
  handleValueChange(value) {
    if (value !== this.args.field.metadata.value) {
      this.mutValue(value);
      this.args.saveAutomation();
    }
  }

  @action
  openModal() {
    this.showJsonEditorModal = true;
  }

  @action
  closeModal() {
    this.showJsonEditorModal = false;
  }
}
