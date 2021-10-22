class PonIdToCommentsTable < ActiveRecord::Migration
  def up
    add_column :comments, :pon_id, :integer
  end

  def down
    remove_column :comments, :pon_id
  end
end
