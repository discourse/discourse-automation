# frozen_string_literal: true

DiscourseAutomation::Triggerable::RECURRING = 'recurring'

RECURRENCE_CHOICES = [
  { id: 'every_minute', name: 'discourse_automation.triggerables.recurring.recurrences.every_minute' },
  { id: 'every_hour', name: 'discourse_automation.triggerables.recurring.recurrences.every_hour' },
  { id: 'every_day', name: 'discourse_automation.triggerables.recurring.recurrences.every_day' },
  { id: 'every_weekday', name: 'discourse_automation.triggerables.recurring.recurrences.every_weekday' },
  { id: 'every_week', name: 'discourse_automation.triggerables.recurring.recurrences.every_week' },
  { id: 'every_other_week', name: 'discourse_automation.triggerables.recurring.recurrences.every_other_week' },
  { id: 'every_month', name: 'discourse_automation.triggerables.recurring.recurrences.every_month' },
]

def setup_pending_automation(automation, fields)
  automation.pending_automations.destroy_all

  expected_recurrence = fields.dig('recurrence', 'value')
  return if !expected_recurrence

  case expected_recurrence
  when 'every_day'
    next_trigger_date = RRule::Rule
      .new('FREQ=DAILY', dtstart: Time.now)
      .between(Time.now, Time.now + 2.days)
      .first
  when 'every_month'
    next_trigger_date = RRule::Rule
      .new('FREQ=MONTHLY', dtstart: Time.now)
      .between(Time.now, Time.now + 2.months)
      .first
  when 'every_weekday'
    next_trigger_date = RRule::Rule
      .new('FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR', dtstart: Time.now)
      .between(Time.now.end_of_day, Time.now + 3.days)
      .first
  when 'every_week'
    next_trigger_date = RRule::Rule
      .new('FREQ=WEEKLY;INTERVAL=1', dtstart: Time.now)
      .between(Time.now, Time.now + 2.weeks)
      .first
  when 'every_other_week'
    next_trigger_date = RRule::Rule
      .new('FREQ=WEEKLY;INTERVAL=2', dtstart: Time.now)
      .between(Time.now + 1.week, Time.now + 2.months)
      .first
  when 'every_hour'
    next_trigger_date = (Time.zone.now + 1.hour).beginning_of_hour
  when 'every_minute'
    next_trigger_date = (Time.zone.now + 1.minute).beginning_of_minute
  when 'every_year'
    next_trigger_date = RRule::Rule
      .new('FREQ=YEARLY', dtstart: Time.now)
      .between(Time.now, Time.now + 2.years)
      .first
  end

  if next_trigger_date && next_trigger_date > Time.zone.now
    automation
      .pending_automations
      .create!(execute_at: next_trigger_date)
  end
end

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::RECURRING) do
  field :recurrence, component: :choices, extra: { content: RECURRENCE_CHOICES }

  on_update { |automation, fields| setup_pending_automation(automation, fields) }
  on_call { |automation, fields| setup_pending_automation(automation, fields) }
end
