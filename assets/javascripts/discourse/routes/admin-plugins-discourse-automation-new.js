import { hash } from "rsvp";
import DiscourseRoute from "discourse/routes/discourse";

export default class AutomationNew extends DiscourseRoute {
  controllerName = "admin-plugins-discourse-automation-new";

  model() {
    return hash({
      scriptables: this.store.findAll("discourse-automation-scriptable"),
      automation: this.store.createRecord("discourse-automation-automation"),
    });
  }
}
