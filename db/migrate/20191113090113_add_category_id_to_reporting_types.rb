class AddCategoryIdToReportingTypes < ActiveRecord::Migration
  def up
    add_column :reporting_types, :category_id, :integer
  end

  def down
    remove_column :reporting_types, :category_id
  end
end
