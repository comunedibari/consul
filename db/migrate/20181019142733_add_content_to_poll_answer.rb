class AddContentToPollAnswer < ActiveRecord::Migration
  def change
    add_column :poll_answers, :content, :string,:default => ""
  end
end
