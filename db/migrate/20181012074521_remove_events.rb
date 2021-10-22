class RemoveEvents < ActiveRecord::Migration
  def change
    drop_table :events, force: :cascade
  end
end
