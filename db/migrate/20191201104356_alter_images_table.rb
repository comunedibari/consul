class AlterImagesTable < ActiveRecord::Migration
  def up
    change_column :images, :title, :string, limit: 500
  end

  def down
    change_column :images, :title, :string, limit: 80
  end
end
