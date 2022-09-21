import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { makeArray } from "discourse-common/lib/helpers";
import { withPluginApi } from "discourse/lib/plugin-api";

let _lastCheckedByHandlers = {};

function _handleLastCheckedByEvent(event) {
  ajax(`/append-last-checked-by/${event.currentTarget.postId}`, {
    type: "PUT",
  }).catch(popupAjaxError);
}

function _cleanUp() {
  Object.values(_lastCheckedByHandlers || {}).forEach((handler) => {
    handler.removeEventListener("click", _handleLastCheckedByEvent);
  });

  _lastCheckedByHandlers = {};
}

function _initializeDiscourseAutomation(api) {
  _initializeGLobalUserNotices(api);

  if (api.getCurrentUser()) {
    api.decorateCookedElement(_decorateCheckedButton, {
      id: "discourse-automation",
    });

    api.cleanupStream(_cleanUp);
  }

  api.modifyClass("controller:create-account", {
    pluginId: "discourse-automation",
    addToMailingList: false,
    performAccountCreation() {
      if (
        !this._challengeDate ||
        new Date() - this._challengeDate > 1000 * this._challengeExpiry
      ) {
        return this.fetchConfirmationValue().then(() =>
          this.performAccountCreation()
        );
      }

      const attrs = this.getProperties(
        "accountName",
        "accountEmail",
        "accountPassword",
        "accountUsername",
        "accountChallenge",
        "inviteCode"
      );

      attrs["accountPasswordConfirm"] = this.accountHoneypot;

      const userFields = this.userFields;
      const destinationUrl = this.get("authOptions.destination_url");

      if (!isEmpty(destinationUrl)) {
        cookie("destination_url", destinationUrl, { path: "/" });
      }

      // Add the userfields to the data
      if (!isEmpty(userFields)) {
        attrs.userFields = {};
        userFields.forEach(
          (f) => (attrs.userFields[f.get("field.id")] = f.get("value"))
        );
      }

      attrs["customFields"] = {
        add_to_mailing_list: this.addToMailingList,
      };

      this.set("formSubmitted", true);
      return User.createAccount(attrs).then(
        (result) => {
          if (this.isDestroying || this.isDestroyed) {
            return;
          }

          this.set("isDeveloper", false);
          if (result.success) {
            // invalidate honeypot
            this._challengeExpiry = 1;

            // Trigger the browser's password manager using the hidden static login form:
            const $hidden_login_form = $("#hidden-login-form");
            $hidden_login_form
              .find("input[name=username]")
              .val(attrs.accountUsername);
            $hidden_login_form
              .find("input[name=password]")
              .val(attrs.accountPassword);
            $hidden_login_form
              .find("input[name=redirect]")
              .val(userPath("account-created"));
            $hidden_login_form.submit();
            return new Promise(() => {}); // This will never resolve, the page will reload instead
          } else {
            this.flash(
              result.message || I18n.t("create_account.failed"),
              "error"
            );
            if (result.is_developer) {
              this.set("isDeveloper", true);
            }
            if (
              result.errors &&
              result.errors.email &&
              result.errors.email.length > 0 &&
              result.values
            ) {
              this.rejectedEmails.pushObject(result.values.email);
            }
            if (
              result.errors &&
              result.errors.password &&
              result.errors.password.length > 0
            ) {
              this.rejectedPasswords.pushObject(attrs.accountPassword);
            }
            this.set("formSubmitted", false);
            removeCookie("destination_url");
          }
        },
        () => {
          this.set("formSubmitted", false);
          removeCookie("destination_url");
          return this.flash(I18n.t("create_account.failed"), "error");
        }
      );
    },
  });

  api.modifyClass("model:user", {
    pluginId: "discourse-automation",
    createAccount(attrs) {
      let data = {
        name: attrs.accountName,
        email: attrs.accountEmail,
        password: attrs.accountPassword,
        username: attrs.accountUsername,
        password_confirmation: attrs.accountPasswordConfirm,
        challenge: attrs.accountChallenge,
        user_fields: attrs.userFields,
        timezone: moment.tz.guess(),
      };

      if (attrs.customFields) {
        data.custom_fields = attrs.customFields;
      }

      if (attrs.inviteCode) {
        data.invite_code = attrs.inviteCode;
      }

      return ajax(userPath(), {
        data,
        type: "POST",
      });
    },
  });
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

    if (_lastCheckedByHandlers[postId]) {
      _lastCheckedByHandlers[postId].removeEventListener(
        "click",
        _handleLastCheckedByEvent,
        false
      );
      delete _lastCheckedByHandlers[postId];
    }

    _lastCheckedByHandlers[postId] = elem;
    elem.addEventListener("click", _handleLastCheckedByEvent, false);
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
