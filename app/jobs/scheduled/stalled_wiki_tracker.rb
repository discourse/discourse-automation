# frozen_string_literal: true

module Jobs
  class StalledWikiTracker < ::Jobs::Scheduled
    every 1.minute

    def execute(_args = nil)
      name = DiscourseAutomation::Triggerable::STALLED_WIKI

      DiscourseAutomation::Trigger
        .where(name: name)
        .find_each do |trigger|
          stalled_duration = ISO8601::Duration.new(trigger.metadata['stalled_after']).to_seconds
          finder = Post.where(id: 1748435).where('wiki = TRUE AND last_version_at <= ?', stalled_duration.seconds.ago)
          finder.each do |post|
            last_trigger_date = post.custom_fields['stalled_wiki_triggered_at']

            if last_trigger_date
              retrigger_duration = ISO8601::Duration.new(trigger.metadata['retriggered_after']).to_seconds

              if post.id == 1748435
                p last_trigger_date
                p retrigger_duration
                p Time.parse(last_trigger_date) + retrigger_duration
                p Time.zone.now
              end

              if Time.parse(last_trigger_date) + retrigger_duration < Time.zone.now
                p "should trigger?"
                post.upsert_custom_fields(stalled_wiki_triggered_at: Time.zone.now)
                run_trigger(trigger, post)
              else
                next
              end
            else
              post.upsert_custom_fields(stalled_wiki_triggered_at: Time.zone.now)
              run_trigger(trigger, post)
            end
          end
        end
    end

    def run_trigger(trigger, post)
      user_ids = post
        .post_revisions
        .order('post_revisions.created_at DESC')
        .limit(20)
        .pluck(:user_id)
        .uniq

      p user_ids

      trigger.run!(
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
