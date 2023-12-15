import { render } from "@ember/test-helpers";
import { hbs } from "ember-cli-htmlbars";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import fabricators from "discourse/plugins/discourse-automation/discourse/lib/fabricators";

module("Integration | Component | da-users-field", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.automation = fabricators.automation();

    pretender.get("/u/search/users", () =>
      response({
        users: [
          {
            username: "sam",
            avatar_template:
              "https://avatars.discourse.org/v3/letter/t/41988e/{size}.png",
          },
          {
            username: "joffrey",
            avatar_template:
              "https://avatars.discourse.org/v3/letter/t/41988e/{size}.png",
          },
        ],
      })
    );
  });

  test("sets values", async function (assert) {
    this.field = fabricators.field({
      component: "users",
    });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );

    await selectKit().expand();
    await selectKit().fillInFilter("sam");
    await selectKit().selectRowByValue("sam");
    await selectKit().fillInFilter("joffrey");
    await selectKit().selectRowByValue("joffrey");

    assert.deepEqual(this.field.metadata.value, ["sam", "joffrey"]);
  });

  test("allows emails", async function (assert) {
    this.field = fabricators.field({
      component: "users",
    });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );

    await selectKit().expand();
    await selectKit().fillInFilter("j.jaffeux@example.com");
    await selectKit().selectRowByValue("j.jaffeux@example.com");

    assert.deepEqual(this.field.metadata.value, ["j.jaffeux@example.com"]);
  });
});
