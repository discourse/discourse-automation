import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { makeArray } from "discourse-common/lib/helpers";
import { withPluginApi } from "discourse/lib/plugin-api";

let _btnClickHandlers = {};

function _handleEvent(event) {
  ajax(`/append-last-checked-by/${event.currentTarget.postId}`, { type: "PUT" }).catch(
    popupAjaxError
  );
}

function _initializeDiscourseAutomation(api) {
  function _cleanUp() {
    Object.values(_btnClickHandlers || {}).forEach((handler) => {
      handler.removeEventListener("click", _handleEvent);
    });

    _btnClickHandlers = {};
  }

  _initializeGLobalUserNotices(api);

  if (api.getCurrentUser()) {
    api.decorateCookedElement(_decorateCheckedButton, {
      id: "discourse-automation",
    });

    api.cleanupStream(_cleanUp);
  }
}

function _decorateCheckedButton(element, postDecorator) {
  if (!postDecorator) {
    return;
  }

  const elems = element.querySelectorAll(".btn-checked");
  const postModel = postDecorator.getModel();

  Array.from(elems).forEach((elem) => {
    const postId = postModel.id;
    elem.postId = postId;

    if (_btnClickHandlers[postId]) {
      _btnClickHandlers[postId].removeEventListener("click", _handleEvent, false);
      delete _btnClickHandlers[postId];
    }

    _btnClickHandlers[postId] = elem;
    elem.addEventListener("click", _handleEvent, false);
  });
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

  initialize() {
    withPluginApi("0.8.24", _initializeDiscourseAutomation);
  },
};
