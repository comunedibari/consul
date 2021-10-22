class AddPonIdToSectors < ActiveRecord::Migration
  def up
    add_column :sectors, :pon_id, :integer
    add_column :sectors, :note, :string, default: ''
    add_column :sectors, :visible, :boolean, default: :true
  end

  def down
    remove_column :sectors, :pon_id
    remove_column :sectors, :note
    remove_column :sectors, :visible
  end
end
