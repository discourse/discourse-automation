# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'PostCreatedEdited' do
  let(:basic_topic_params) { { title: 'hello world topic', raw: 'my name is fred', archetype_id: 1 } }
  fab!(:user) { Fabricate(:user) }
  fab!(:automation) { Fabricate(:automation, trigger: DiscourseAutomation::Triggerable::POST_CREATED_EDITED) }

  context 'editing/creating a post' do
    it 'fires the trigger' do
      post = nil

      output = capture_stdout do
        post = PostCreator.create(user, basic_topic_params)
      end

      expect(output).to include('Howdy!')

      output = capture_stdout do
        post.revise(post.user, raw: 'this is another cool topic')
      end

      expect(output).to include('Howdy!')
    end
  end
end
