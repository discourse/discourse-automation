# frozen_string_literal: true

DiscourseAutomation::Triggerable::STALLED_WIKI = 'stalled_wiki'

DURATION_CHOICES = [
  { id: 'PT10S', name: '10 seconds'},
  { id: 'PT1M', name: '1 minute'},
  { id: 'PT1H', name: '1 hour'},
  { id: 'PT1H', name: '1 hour'},
  { id: 'PT10H', name: '10 hours'},
]

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::STALLED_WIKI) do
  set_metadata :stalled_after_choices, DURATION_CHOICES
  set_metadata :retriggered_after_choices, DURATION_CHOICES

  placeholder :post_url
end
