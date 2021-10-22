class AddSectorToSectorContent < ActiveRecord::Migration
  def change

    add_reference :sector_contents, :sector, index: true, foreign_key: true, null: true

  end
end
