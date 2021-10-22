class CreateSectorTypes < ActiveRecord::Migration
  def change
    create_table :sector_types do |t|
      t.string :name
    end
  end
end
