# frozen_string_literal: true

DiscourseAutomation::Triggerable::RECURRING = 'recurring'

RECURRENCE_CHOICES = [
  { id: 'minute', name: 'discourse_automation.triggerables.recurring.frequencies.minute' },
  { id: 'hour', name: 'discourse_automation.triggerables.recurring.frequencies.hour' },
  { id: 'day', name: 'discourse_automation.triggerables.recurring.frequencies.day' },
  { id: 'weekday', name: 'discourse_automation.triggerables.recurring.frequencies.weekday' },
  { id: 'week', name: 'discourse_automation.triggerables.recurring.frequencies.week' },
  { id: 'month', name: 'discourse_automation.triggerables.recurring.frequencies.month' },
  { id: 'year', name: 'discourse_automation.triggerables.recurring.frequencies.year' },
]

def setup_pending_automation(automation, fields)
  automation.pending_automations.destroy_all

  start_date = fields.dig('start_date', 'value')
  return if !start_date
  start_date = Time.parse(start_date)

  interval = fields.dig('recurrence', 'value', 'interval')
  return if !interval

  frequency = fields.dig('recurrence', 'value', 'frequency')
  return if !frequency

  byday = start_date.strftime('%A').upcase[0, 2]
  interval = interval.to_i
  interval_end = interval + 1

  case frequency
  when 'day'
    next_trigger_date = RRule::Rule
      .new("FREQ=DAILY;INTERVAL=#{interval}", dtstart: start_date)
      .between(Time.now.end_of_day, interval_end.days.from_now)
      .first
  when 'month'
    count = 0
    (start_date.beginning_of_month.to_date..start_date.end_of_month.to_date).each do |date|
      count += 1 if date.strftime('%A') == start_date.strftime('%A')
      break if date.day == start_date.day
    end

    next_trigger_date = RRule::Rule
      .new("FREQ=MONTHLY;INTERVAL=#{interval};BYDAY=#{count}#{byday}", dtstart: start_date)
      .between(Time.now, interval_end.months.from_now)
      .first
  when 'weekday'
    next_trigger_date = RRule::Rule
      .new("FREQ=DAILY;INTERVAL=#{interval};BYDAY=MO,TU,WE,TH,FR", dtstart: start_date)
      .between(Time.now.end_of_day, (interval_end + 1).days.from_now)
      .first
  when 'week'
    next_trigger_date = RRule::Rule
      .new("FREQ=WEEKLY;INTERVAL=#{interval};BYDAY=#{byday}", dtstart: start_date)
      .between(Time.now.end_of_week, interval_end.weeks.from_now)
      .first
  when 'hour'
    next_trigger_date = (Time.zone.now + interval.hour).beginning_of_hour
  when 'minute'
    next_trigger_date = (Time.zone.now + interval.minute).beginning_of_minute
  when 'year'
    next_trigger_date = RRule::Rule
      .new("FREQ=YEARLY;INTERVAL=#{interval}", dtstart: start_date)
      .between(Time.now, interval_end.years.from_now)
      .first
  end

  if next_trigger_date && next_trigger_date > Time.zone.now
    automation
      .pending_automations
      .create!(execute_at: next_trigger_date)
  end
end

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::RECURRING) do
  field :recurrence, component: :period, extra: { content: RECURRENCE_CHOICES }, required: true
  field :start_date, component: :date_time, required: true

  on_update { |automation, fields| setup_pending_automation(automation, fields) }
  on_call { |automation, fields| setup_pending_automation(automation, fields) }
end
