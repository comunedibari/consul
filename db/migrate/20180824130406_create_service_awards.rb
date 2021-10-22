class CreateServiceAwards < ActiveRecord::Migration
  def change
    create_table :service_awards do |t|
      t.text :service_award
      t.integer :score
      t.string :code
    end
  end
end
