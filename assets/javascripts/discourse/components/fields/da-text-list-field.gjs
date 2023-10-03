import BaseField from "./da-base-field";
import MultiSelect from "select-kit/components/multi-select";
import DAFieldLabel from "./da-field-label";
import DAFieldDescription from "./da-field-description";
import { hash } from "@ember/helper";

export default class TextListField extends BaseField {
  <template>
    <section class="field text-list-field">
      <div class="control-group">
        <DAFieldLabel @label={{@label}} @field={{@field}} />

        <div class="controls">
          <MultiSelect
            @value={{@field.metadata.value}}
            @content={{@field.metadata.value}}
            @onChange={{this.mutValue}}
            @nameProperty={{null}}
            @valueProperty={{null}}
            @options={{hash allowAny=true disabled=@field.isDisabled}}
          />

          <DAFieldDescription @description={{@description}} />
        </div>
      </div>
    </section>
  </template>
}
