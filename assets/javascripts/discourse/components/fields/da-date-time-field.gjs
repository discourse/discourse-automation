import BaseField from "./da-base-field";
import { action } from "@ember/object";
import { Input } from "@ember/component";
import DAFieldLabel from "./da-field-label";
import DAFieldDescription from "./da-field-description";
import DButton from "discourse/components/d-button";
import { on } from "@ember/modifier";

export default class DateTimeField extends BaseField {
  <template>
    <section class="field date-field">
      <div class="control-group">
        <DAFieldLabel @label={{@label}} @field={{@field}} />

        <div class="controls">
          <div class="controls-row">
            <Input
              @type="datetime-local"
              @value={{readonly this.localTime}}
              disabled={{@field.isDisabled}}
              {{on "input" this.convertToUniversalTime}}
            />

            {{#if @field.metadata.value}}
              <DButton
                @icon="trash-alt"
                @action={{this.reset}}
                @disabled={{@field.isDisabled}}
              />
            {{/if}}
          </div>

          <DAFieldDescription @description={{@description}} />
        </div>
      </div>
    </section>
  </template>

  @action
  convertToUniversalTime(event) {
    const date = event.target.value;
    if (!date) {
      return;
    }

    this.mutValue(moment(date).utc().format());
  }

  @action
  reset() {
    this.mutValue(null);
  }

  get localTime() {
    return (
      this.args.field.metadata.value &&
      moment(this.args.field.metadata.value)
        .local()
        .format(moment.HTML5_FMT.DATETIME_LOCAL)
    );
  }
}
