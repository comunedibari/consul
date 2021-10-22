class DropOperationScore < ActiveRecord::Migration
  def change
    drop_table :operation_scores
  end
end
