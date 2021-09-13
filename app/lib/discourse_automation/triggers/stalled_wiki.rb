# frozen_string_literal: true

DiscourseAutomation::Triggerable::STALLED_WIKI = 'stalled_wiki'

DURATION_CHOICES = [
  { id: 'PT1H', name: 'discourse_automation.triggerables.stalled_wiki.durations.PT1H' },
  { id: 'P1D', name: 'discourse_automation.triggerables.stalled_wiki.durations.P1D' },
  { id: 'P1W', name: 'discourse_automation.triggerables.stalled_wiki.durations.P1W' },
  { id: 'P2W', name: 'discourse_automation.triggerables.stalled_wiki.durations.P2W' },
  { id: 'P1M', name: 'discourse_automation.triggerables.stalled_wiki.durations.P1M' },
  { id: 'P3M', name: 'discourse_automation.triggerables.stalled_wiki.durations.P3M' },
  { id: 'P6M', name: 'discourse_automation.triggerables.stalled_wiki.durations.P6M' },
  { id: 'P1Y', name: 'discourse_automation.triggerables.stalled_wiki.durations.P1Y' },
]

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::STALLED_WIKI) do
  field :restricted_category, component: :category
  field :stalled_after, component: :choices, extra: { content: DURATION_CHOICES }, required: true
  field :retriggered_after, component: :choices, extra: { content: DURATION_CHOICES }

  placeholder :wiki_url
end
