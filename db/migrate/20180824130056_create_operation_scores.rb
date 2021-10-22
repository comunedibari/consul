class CreateOperationScores < ActiveRecord::Migration
  def change
    create_table :operation_scores do |t|
      t.text :service
      t.text :operation
      t.integer :score
      t.string :code
    end
  end
end
