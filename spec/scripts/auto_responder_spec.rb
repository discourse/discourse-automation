# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'AutoResponder' do
  fab!(:topic) { Fabricate(:topic) }

  fab!(:automation) do
    Fabricate(
      :automation,
      script: DiscourseAutomation::Scriptable::AUTO_RESPONDER
    )
  end

  context 'without word filter' do
    before do
      automation.upsert_field!('word_answer_list', 'key-value', { value: [{ key: '', value: 'this is the reply' }].to_json })
    end

    it 'creates an answer' do
      post = create_post(topic: topic, raw: 'this is a post')
      automation.trigger!('post' => post)

      expect(topic.reload.posts.last.raw).to eq('this is the reply')
    end
  end

  context 'present word_answer list' do
    before do
      automation.upsert_field!('word_answer_list', 'key-value', { value: [{ key: 'fooz?|bar', value: 'this is %%KEY%%' }, { key: 'bar', value: 'this is %%KEY%%' }].to_json })
    end

    context 'post is first post' do
      context 'topic title contains keywords' do
        it 'creates an answer' do
          topic = Fabricate(:topic, title: 'What a foo day to walk')
          post = create_post(topic: topic, raw: 'this is a post with no keyword')
          automation.trigger!('post' => post)

          expect(topic.reload.posts.last.raw).to eq('this is foo')
        end
      end

      context 'post and topic title contain keyword' do
        it 'creates only one answer' do
          topic = Fabricate(:topic, title: 'What a foo day to walk')
          post = create_post(topic: topic, raw: 'this is a post with foo keyword')
          automation.trigger!('post' => post)

          expect(topic.reload.posts.last.raw).to eq('this is foo')
        end
      end
    end

    context 'post contains a keyword' do
      it 'creates an answer' do
        post = create_post(topic: topic, raw: 'this is foo a post with foo')
        automation.trigger!('post' => post)

        expect(topic.reload.posts.last.raw).to eq('this is foo')
      end

      context 'post has direct replies from answering user' do
        fab!(:answering_user) { Fabricate(:user) }

        before do
          automation.upsert_field!('answering_user', 'user', { value: answering_user.username }, target: 'script')
        end

        it 'doesn’t create another answer' do
          post_1 = create_post(topic: topic, raw: 'this is a post with foo')
          create_post(user: answering_user, reply_to_post_number: post_1.post_number, topic: topic)

          expect {
            automation.trigger!('post' => post_1)
          }.not_to change {
            Post.count
          }
        end
      end

      context 'user is replying to own post' do
        fab!(:answering_user) { Fabricate(:user) }

        before do
          automation.upsert_field!('answering_user', 'user', { value: answering_user.username }, target: 'script')
        end

        it 'doesn’t create an answer' do
          post_1 = create_post(topic: topic)
          post_2 = create_post(user: answering_user, topic: topic, reply_to_post_number: post_1.post_number, raw: 'this is a post with foo')

          expect {
            automation.trigger!('post' => post_2)
          }.not_to change {
            Post.count
          }
        end
      end
    end

    context 'post contains two keywords' do
      it 'creates an answer with both answers' do
        post = create_post(topic: topic, raw: 'this is a post with FOO and bar')
        automation.trigger!('post' => post)

        expect(topic.reload.posts.last.raw).to eq("this is FOO\n\nthis is bar")
      end
    end

    context 'post doesn’t contain a keyword' do
      it 'doesn’t create an answer' do
        post = create_post(topic: topic, raw: 'this is a post with no keyword')

        expect {
          automation.trigger!('post' => post)
        }.not_to change {
          Post.count
        }
      end
    end

    context 'post contains two keywords' do
      it 'creates an answer with both answers' do
        post = create_post(topic: topic, raw: 'this is a post with foo and bar')
        automation.trigger!('post' => post)

        expect(topic.reload.posts.last.raw).to eq("this is foo\n\nthis is bar")
      end
    end

    context 'post doesn’t contain a keyword' do
      it 'doesn’t create an answer' do
        post = create_post(topic: topic, raw: 'this is a post bfoo with no keyword fooa')

        expect {
          automation.trigger!('post' => post)
        }.not_to change {
          Post.count
        }
      end
    end
  end

  context 'empty word_answer list' do
    it 'exits early with no error' do
      expect {
        post = create_post(topic: topic, raw: 'this is a post with foo and bar')
        automation.trigger!('post' => post)
      }.to_not raise_error
    end
  end
end
