class AddHtmlMapCoordinatesToPons < ActiveRecord::Migration
  def change
    add_column :pons, :html_map_coordinates, :string
  end
end
