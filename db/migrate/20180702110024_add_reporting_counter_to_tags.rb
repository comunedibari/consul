class AddReportingCounterToTags < ActiveRecord::Migration
  def change
    add_column :tags, :reportings_count, :integer, default: 0
    add_index :tags, :reportings_count
  end
end
