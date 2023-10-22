import { module, test } from "qunit";
import { hbs } from "ember-cli-htmlbars";
import { render } from "@ember/test-helpers";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import fabricators from "discourse/plugins/discourse-automation/discourse/lib/fabricators";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import pretender, { response } from "discourse/tests/helpers/create-pretender";

module("Integration | Component | da-custom-field", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.automation = fabricators.automation();

    pretender.get("/admin/customize/user_fields", () => {
      return response({
        user_fields: [
          {
            id: 1,
            name: "Title",
            description: "your title",
            field_type: "text",
            editable: true,
            required: true,
            show_on_profile: true,
            show_on_user_card: true,
            searchable: true,
            position: 1,
          },
        ],
      });
    });
  });

  test("set value", async function (assert) {
    this.field = fabricators.field({ component: "custom_field" });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );

    await selectKit().expand();
    await selectKit().selectRowByValue(1);
    assert.strictEqual(this.field.metadata.value, 1);
  });
});
