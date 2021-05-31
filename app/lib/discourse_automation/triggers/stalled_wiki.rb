# frozen_string_literal: true

DiscourseAutomation::Triggerable::STALLED_WIKI = 'stalled_wiki'

DURATION_CHOICES = [
  { id: 'PT1H', name: 'One hour'},
  { id: 'P1D', name: 'One day'},
  { id: 'P1W', name: 'One week'},
  { id: 'P2W', name: 'Two weeks'},
  { id: 'P1M', name: 'One month'},
  { id: 'P3M', name: 'Three months'},
  { id: 'P6M', name: 'Six months'},
  { id: 'P1Y', name: 'One year'},
]

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::STALLED_WIKI) do
  field :restricted_category, component: :category
  field :stalled_after, component: :choices
  field :retriggered_after, component: :choices

  placeholder :post_url
end
