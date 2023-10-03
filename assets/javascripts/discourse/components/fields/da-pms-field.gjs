import BaseField from "./da-base-field";
import I18n from "I18n";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { concat, fn } from "@ember/helper";
import DAFieldLabel from "./da-field-label";
import DButton from "discourse/components/d-button";
import { Input } from "@ember/component";
import PlaceholdersList from "../placeholders-list";
import DEditor from "discourse/components/d-editor";
import { on } from "@ember/modifier";
import { TrackedArray, TrackedObject } from "@ember-compat/tracked-built-ins";
import { next } from "@ember/runloop";

export default class PmsField extends BaseField {
  <template>
    <section class="field pms-field">
      {{#if @field.metadata.value.length}}
        <section class="actions header">
          <DAFieldLabel @label={{@label}} @field={{@field}} />
          <DButton
            @icon="plus"
            @action={{this.insertPM}}
            class="btn-primary insert-pm"
          />
        </section>
      {{/if}}

      {{#each @field.metadata.value as |pm|}}
        <div class="pm-field">
          <div class="control-group">
            <DAFieldLabel @label={{this.pmTitleLabel}} @field={{@field}} />
            <div class="controls">
              <div class="field-wrapper">
                <Input
                  id={{concat @field.target @field.name "title"}}
                  @value={{pm.title}}
                  class="pm-input pm-title"
                  {{on "input" (fn this.mutPmTitle pm)}}
                  disabled={{@field.isDisabled}}
                  name={{@field.name}}
                />

                {{#if this.displayPlaceholders}}
                  <PlaceholdersList
                    @currentValue={{pm.title}}
                    @placeholders={{@placeholders}}
                    @onCopy={{fn this.updatePmTitle pm}}
                  />
                {{/if}}
              </div>
            </div>
          </div>

          <div class="control-group">
            <DAFieldLabel @label={{this.rawLabel}} @field={{@field}} />
            <div class="controls">
              <div class="field-wrapper">
                <DEditor @value={{pm.raw}} />

                {{#if this.displayPlaceholders}}
                  <PlaceholdersList
                    @currentValue={{pm.raw}}
                    @placeholders={{@placeholders}}
                    @onCopy={{fn this.updatePmRaw pm}}
                  />
                {{/if}}
              </div>
            </div>
          </div>

          <div class="control-group">
            <label class="control-label">
              {{this.delayLabel}}
            </label>

            <div class="controls">
              <Input
                @value={{pm.delay}}
                class="input-large pm-input pm-delay"
                {{on "input" (fn this.mutPmDelay pm)}}
                disabled={{@field.isDisabled}}
              />
            </div>
          </div>

          <div class="control-group">
            <label class="control-label">
              {{this.prefersEncryptLabel}}
            </label>

            <div class="controls">
              <Input
                @type="checkbox"
                class="pm-prefers-encrypt"
                @checked={{pm.prefers_encrypt}}
                {{on "click" (fn this.prefersEncrypt pm)}}
                disabled={{@field.isDisabled}}
              />
            </div>
          </div>
          <section class="actions">
            <DButton
              @icon="trash-alt"
              @action={{fn this.removePM pm}}
              class="btn-danger"
              @disabled={{@field.isDisabled}}
            />
          </section>
        </div>
      {{else}}
        <div class="no-pm">
          <p>{{this.noPmCreatedLabel}}</p>
          <DButton
            @icon="plus"
            @label="discourse_automation.fields.pms.add_pm"
            @action={{this.insertPM}}
            class="btn-primary insert-pm"
            @disabled={{@field.isDisabled}}
          />
        </div>
      {{/each}}
    </section>
  </template>

  @service dialog;

  noPmCreatedLabel = I18n.t("discourse_automation.fields.pms.no_pm_created");

  prefersEncryptLabel = I18n.t(
    "discourse_automation.fields.pms.prefers_encrypt.label"
  );

  delayLabel = I18n.t("discourse_automation.fields.pms.delay.label");

  pmTitleLabel = I18n.t("discourse_automation.fields.pms.title.label");

  rawLabel = I18n.t("discourse_automation.fields.pms.raw.label");

  constructor() {
    super(...arguments);

    // a hack to prevent warnings about modifying multiple times in the same runloop
    next(() => {
      this.args.field.metadata.value = new TrackedArray(
        (this.args.field.metadata.value || []).map((pm) => {
          return new TrackedObject(pm);
        })
      );
    });
  }

  @action
  removePM(pm) {
    this.dialog.yesNoConfirm({
      message: I18n.t("discourse_automation.fields.pms.confirm_remove_pm"),
      didConfirm: () => {
        return this.args.field.metadata.value.removeObject(pm);
      },
    });
  }

  @action
  insertPM() {
    this.args.field.metadata.value.pushObject(
      new TrackedObject({
        title: "",
        raw: "",
        delay: 0,
        prefers_encrypt: true,
      })
    );
  }

  @action
  prefersEncrypt(pm, event) {
    pm.prefers_encrypt = event.target.checked;
  }

  @action
  mutPmTitle(pm, event) {
    pm.title = event.target.value;
  }

  @action
  mutPmDelay(pm, event) {
    pm.delay = event.target.value;
  }

  @action
  updatePmRaw(pm, newRaw) {
    pm.raw = newRaw;
  }

  @action
  updatePmTitle(pm, newRaw) {
    pm.title = newRaw;
  }
}
