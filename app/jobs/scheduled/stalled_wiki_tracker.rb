# frozen_string_literal: true

module Jobs
  class StalledWikiTracker < ::Jobs::Scheduled
    every 10.minutes

    def execute(_args = nil)
      name = DiscourseAutomation::Triggerable::STALLED_WIKI

      DiscourseAutomation::Automation
        .where(trigger: name)
        .find_each do |automation|

          stalled_after = automation.trigger_field('stalled_after')
          stalled_duration = ISO8601::Duration.new(stalled_after['value']).to_seconds
          finder = Post.where('wiki = TRUE AND last_version_at <= ?', stalled_duration.seconds.ago)

          restricted_category = automation.trigger_field('restricted_category')
          if restricted_category['category_id']
            finder = finder.joins(:topic).where('topics.category_id = ?', restricted_category['category_id'])
          end

          finder.each do |post|
            last_trigger_date = post.custom_fields['stalled_wiki_triggered_at']
            if last_trigger_date
              retriggered_after = automation.trigger_field('retriggered_after')
              retrigger_duration = ISO8601::Duration.new(retriggered_after['value']).to_seconds

              if Time.parse(last_trigger_date) + retrigger_duration >= Time.zone.now
                next
              end
            end

            post.upsert_custom_fields(stalled_wiki_triggered_at: Time.zone.now)
            run_trigger(automation, post)
          end
        end
    end

    def run_trigger(automation, post)
      user_ids = post
        .post_revisions
        .order('post_revisions.created_at DESC')
        .limit(20)
        .pluck(:user_id)
        .uniq

      automation.trigger!(
        'kind' => DiscourseAutomation::Triggerable::STALLED_WIKI,
        'post' => post,
        'users' => User.where(id: user_ids),
        'placeholders' => {
          'post_url' => Discourse.base_url + post.url
        }
      )
    end
  end
end
