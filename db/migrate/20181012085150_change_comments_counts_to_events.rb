class ChangeCommentsCountsToEvents < ActiveRecord::Migration
  def change
    rename_column :events, :comments_counts, :comments_count
  end
end
