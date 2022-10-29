# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'Recurring' do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
  fab!(:automation) do
    Fabricate(:automation, trigger: DiscourseAutomation::Triggerable::RECURRING, script: 'nothing_about_us')
  end

  def upsert_period_field!(interval, frequency)
    metadata = {
      value: {
        interval: interval,
        frequency: frequency
      }
    }
    automation.upsert_field!('recurrence', 'period', metadata, target: 'trigger')
  end

  it "allows manual trigger" do
    triggerable = DiscourseAutomation::Triggerable.new(automation.trigger)
    expect(triggerable.settings[DiscourseAutomation::Triggerable::MANUAL_TRIGGER_KEY]).to eq(true)
  end

  describe 'updating trigger' do
    context 'when date is in future' do
      before do
        freeze_time Time.parse('2021-06-04 10:00 UTC')
      end

      it 'creates a pending trigger' do
        expect {
          automation.upsert_field!('start_date', 'date_time', { value: 2.hours.from_now }, target: 'trigger')
          upsert_period_field!(1, 'hour')
        }.to change {
          DiscourseAutomation::PendingAutomation.count
        }.by(1)

        expect(DiscourseAutomation::PendingAutomation.last.execute_at).to be_within_one_minute_of(1.hours.from_now)
      end
    end

    context 'when date is in past' do
      it 'doesn’t create a pending trigger' do
        expect {
          automation.upsert_field!('start_date', 'date_time', { value: 2.hours.ago }, target: 'trigger')
        }.not_to change {
          DiscourseAutomation::PendingAutomation.count
        }
      end
    end
  end

  context 'when trigger is called' do
    before do
      freeze_time Time.zone.parse('2021-06-04 10:00')
      automation.fields.insert!(name: 'start_date', component: 'date_time', metadata: { value: 2.hours.ago }, target: 'trigger', created_at: Time.now, updated_at: Time.now)
      metadata = {
        value: {
          interval: "1",
          frequency: "week"
        }
      }
      automation.fields.insert!(name: 'recurrence', component: 'period', metadata: metadata, target: 'trigger', created_at: Time.now, updated_at: Time.now)
    end

    it 'creates the next iteration' do
      expect {
        automation.trigger!
      }.to change {
        DiscourseAutomation::PendingAutomation.count
      }.by(1)

      pending_automation = DiscourseAutomation::PendingAutomation.last

      start_date = Time.parse(automation.trigger_field('start_date')['value'])
      expect(pending_automation.execute_at).to be_within_one_minute_of(start_date + 7.days)
    end

    describe 'every_month' do
      before do
        upsert_period_field!(1, 'month')
      end

      it 'creates the next iteration one month later' do
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        expect(pending_automation.execute_at).to be_within_one_minute_of(Time.parse('2021-07-02 08:00:00 UTC'))
      end
    end

    describe 'every_day' do
      before do
        upsert_period_field!(1, 'day')
      end

      it 'creates the next iteration one day later' do
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        start_date = Time.parse(automation.trigger_field('start_date')['value'])
        expect(pending_automation.execute_at).to be_within_one_minute_of(start_date + 1.day)
      end
    end

    describe 'every_weekday' do
      it 'creates the next iteration one day after without Saturday/Sunday' do
        upsert_period_field!(1, 'weekday')
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        start_date = Time.parse(automation.trigger_field('start_date')['value'])
        expect(pending_automation.execute_at).to be_within_one_minute_of(start_date + 3.day)
      end

      it 'creates the next iteration three days after without Saturday/Sunday' do
        now = DateTime.parse("2022-05-19").end_of_day
        start_date = now - 1.hour
        freeze_time now

        automation.pending_automations.destroy_all
        automation.upsert_field!('start_date', 'date_time', { value: start_date }, target: 'trigger')
        upsert_period_field!(3, 'weekday')

        automation.trigger!

        pending_automation = automation.pending_automations.last
        expect(pending_automation.execute_at).to be_within_one_minute_of(start_date + 5.days)
      end
    end

    describe 'every_hour' do
      before do
        upsert_period_field!(1, 'hour')
      end

      it 'creates the next iteration one hour later' do
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        expect(pending_automation.execute_at).to be_within_one_minute_of((Time.zone.now + 1.hour).beginning_of_hour)
      end
    end

    describe 'every_minute' do
      before do
        upsert_period_field!(1, 'minute')
      end

      it 'creates the next iteration one minute later' do
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        expect(pending_automation.execute_at).to be_within_one_minute_of((Time.zone.now + 1.minute).beginning_of_minute)
      end
    end

    describe 'every_year' do
      before do
        upsert_period_field!(1, 'year')
      end

      it 'creates the next iteration one year later' do
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        start_date = Time.parse(automation.trigger_field('start_date')['value'])
        expect(pending_automation.execute_at).to be_within_one_minute_of(start_date + 1.year)
      end
    end

    describe 'every_other_week' do
      before do
        upsert_period_field!(2, 'week')
      end

      it 'creates the next iteration two weeks later' do
        automation.trigger!

        pending_automation = DiscourseAutomation::PendingAutomation.last
        start_date = Time.parse(automation.trigger_field('start_date')['value'])
        expect(pending_automation.execute_at).to be_within_one_minute_of(start_date + 2.weeks)
      end
    end
  end
end
