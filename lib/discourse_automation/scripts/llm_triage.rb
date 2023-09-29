# frozen_string_literal: true

DiscourseAutomation::Scriptable::LLM_TRIAGE = "llm_triage"

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::LLM_TRIAGE) do
  version 1

  placeholder :creator_username

  triggerables %i[post_created_edited]

  script { |context, fields, automation| }
end
