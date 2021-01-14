# frozen_string_literal: true

require 'rails_helper'

describe DiscourseAutomation::Scriptable do
  before do
    DiscourseAutomation::Scriptable.add('cats_everywhere') do
      version 1

      placeholder :foo
      placeholder :bar

      field :cat, component: :string
      field :dog, component: :integer, accepts_placeholders: true

      script do
        p 'baz'
      end
    end
  end

  let(:automation) { DiscourseAutomation::Automation.new(script: 'cats_everywhere') }
  let(:scriptable) { DiscourseAutomation::Scriptable.new(automation) }

  describe '#fields' do
    it 'returns the fields' do
      expect(scriptable.fields).to match_array(
        [
          { name: :cat, component: :string, accepts_placeholders: false },
          { name: :dog, component: :integer, accepts_placeholders: true }
        ]
      )
    end
  end

  describe '#script' do
    it 'returns the script proc' do
      expect(scriptable.script.class).to eq(Proc)
    end
  end

  describe '#placeholders' do
    it 'returns the specified placeholders' do
      expect(scriptable.placeholders).to eq(%i[site_title foo bar])
    end
  end

  describe '#version' do
    it 'returns the specified version' do
      expect(scriptable.version).to eq(1)
    end
  end

  describe '.add' do
    it 'adds the script to the list of available scripts' do
      expect(scriptable).to respond_to(:__scriptable_cats_everywhere)
    end
  end

  describe '.all' do
    it 'returns the list of available scripts' do
      expect(DiscourseAutomation::Scriptable.all).to include(:__scriptable_cats_everywhere)
    end
  end

  describe '.name' do
    it 'returns the name of the script' do
      expect(scriptable.name).to eq('cats_everywhere')
    end
  end

  context '.utils' do
    describe '.apply_placeholders' do
      it 'replaces the given string by placeholders' do
        input = 'hello %%COOL_CAT%%'
        map = { cool_cat: 'siberian cat' }
        output = scriptable.utils.apply_placeholders(input, map)
        expect(output).to eq('hello siberian cat')
      end
    end
  end
end
