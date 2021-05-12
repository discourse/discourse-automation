# frozen_string_literal: true

DiscourseAutomation::Scriptable.add('flag_post_on_words') do
  field :words, component: :text_list

  version 1

  triggerables %i[post_created_edited]

  script do |trigger, fields|
    post = trigger['post']

    fields['words']['list'].each do |list|
      words = list.split(',')
      count = words.inject(0) { |acc, word| post.raw.match?(/#{word}/i) ? acc + 1 : acc }
      next if count >= words.length

      has_trust_level = post.user.has_trust_level?(TrustLevel[2])
      p post.user.trust_level
      p has_trust_level
      trusted_user = has_trust_level ||
        ReviewableFlaggedPost
          .where(status: Reviewable.statuses[:rejected], target_created_by: post.user)
          .exists?
      p trusted_user
      next if trusted_user

      message = I18n.t('discourse_automation.scriptables.flag_post_on_words.flag_message', words: list)
      PostActionCreator.new(
        Discourse.system_user,
        post,
        PostActionType.types[:spam],
        message: message,
        queue_for_review: true
      ).perform
    end
  end
end
