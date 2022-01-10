import BaseField from "./da-base-field";
import Site from "discourse/models/site";

export default BaseField.extend({
  allTrustLevel: Site.currentProp("trustLevels"),
});
