class AddSubmittedToPollAnswers < ActiveRecord::Migration
  def change
    add_column :poll_answers, :submitted, :boolean, default: false
  end
end
