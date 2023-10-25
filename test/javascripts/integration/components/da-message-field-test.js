import { fillIn, render } from "@ember/test-helpers";
import { hbs } from "ember-cli-htmlbars";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import fabricators from "discourse/plugins/discourse-automation/discourse/lib/fabricators";

module("Integration | Component | da-message-field", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.automation = fabricators.automation();
  });

  test("set value", async function (assert) {
    this.field = fabricators.field({ component: "message" });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );
    await fillIn("textarea", "Hello World");

    assert.strictEqual(this.field.metadata.value, "Hello World");
  });
});
