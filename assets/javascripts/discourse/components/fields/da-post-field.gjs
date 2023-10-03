import BaseField from "./da-base-field";
import DAFieldLabel from "./da-field-label";
import DAFieldDescription from "./da-field-description";
import PlaceholdersList from "../placeholders-list";
import DEditor from "discourse/components/d-editor";

export default class PostField extends BaseField {
  <template>
    <section class="field post-field">
      <div class="control-group">
        <DAFieldLabel @label={{@label}} @field={{@field}} />

        <div class="controls">
          <div class="field-wrapper">
            <DEditor @value={{@field.metadata.value}} />

            <DAFieldDescription @description={{@description}} />

            {{#if this.displayPlaceholders}}
              <PlaceholdersList
                @currentValue={{@field.metadata.value}}
                @placeholders={{@placeholders}}
                @onCopy={{this.mutValue}}
              />
            {{/if}}
          </div>
        </div>
      </div>
    </section>
  </template>
}
