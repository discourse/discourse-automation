import { iconHTML } from "discourse-common/lib/icon-library";
import { registerUnbound } from "discourse-common/lib/helpers";

registerUnbound("format-enabled-automation", function(enabled, trigger) {
  return (enabled && trigger.id
    ? iconHTML("check", { class: "enabled-automation" })
    : iconHTML("times", { class: "disabled-automation" })
  ).htmlSafe();
});
