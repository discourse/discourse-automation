class PostMigrateGiftFromPmToPms < ActiveRecord::Migration[6.1]
  def up
    DiscourseAutomation::Field.where(name: 'giftee_assignment_message').each do |field|
      if field.metadata['pm']
        pm = field.metadata['pm']

        field.update!(
          name: 'giftee_assignment_messages',
          component: 'pms',
          metadata: {
            pms: [
              { title: pm['title'], raw: pm['body'], delay: pm['delay'] || 0, encrypt: pm['encrypt'] || true }
            ]
          }
        )
      end
    end
  end
end
