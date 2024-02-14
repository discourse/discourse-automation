import { tracked } from "@glimmer/tracking";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { inject as service } from "@ember/service";
import { bind } from "discourse-common/utils/decorators";
import ComboBox from "select-kit/components/combo-box";
import BaseField from "./da-base-field";
import DAFieldDescription from "./da-field-description";
import DAFieldLabel from "./da-field-label";
import MultiSelect from "select-kit/components/multi-select";
import { hash } from "@ember/helper";

export default class GroupField extends BaseField {
  @service store;
  @service currentUser;
  @tracked allProfileFields = [];

  userProfileFields = [
    "bio_raw",
    "website",
    "location",
    "date_of_birth",
    "timezone",
  ];
  <template>
    <section class="field group-field">
      <div class="control-group">
        <DAFieldLabel @label={{@label}} @field={{@field}} />
        <div class="controls">

          <MultiSelect
            @value={{@field.metadata.value}}
            @content={{this.userProfileFields}}
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