import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { makeArray } from "discourse-common/lib/helpers";
import { withPluginApi } from "discourse/lib/plugin-api";

function _initializeDiscourseAutomation(api, container) {
  _initializeGLobalUserNotices(api);
  api.decorateCookedElement((element, postDecorator) => {
    _decorateCheckedButton(element, postDecorator, container);
  },
  {
    id: "discourse-automation",
  });
  api.attachWidgetAction('post', 'onChecked', () => {
    onChecked(container, this);
  });
}

function _decorateCheckedButton(element, postDecorator, container) {
  const elems = element.querySelectorAll(".btn-checked");
  const postModel = postDecorator.getModel();

  Array.from(elems).forEach((elem) => {
    elem.addEventListener("click", onChecked, false);
  });
}

function onChecked(container, postNumber) {
  alert('hi');
}

function _initializeGLobalUserNotices(api) {
  const currentUser = api.getCurrentUser();

  makeArray(currentUser?.global_notices).forEach((userGlobalNotice) => {
    api.addGlobalNotice("", userGlobalNotice.identifier, {
      html: userGlobalNotice.notice,
      level: userGlobalNotice.level,
      dismissable: true,
      dismissDuration: moment.duration(1, "week"),
      onDismiss() {
        ajax(`/user-global-notices/${userGlobalNotice.id}.json`, {
          type: "DELETE",
        }).catch(popupAjaxError);
      },
    });
  });
}

export default {
  name: "discourse-automation",

  initialize(container) {
    withPluginApi("0.8.24", (api) => {
      _initializeDiscourseAutomation(api, container);
    });
  },
};
