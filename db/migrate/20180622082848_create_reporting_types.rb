class CreateReportingTypes < ActiveRecord::Migration
  def change
    create_table :reporting_types do |t|
      t.string   "nome", limit: 80
      t.string   "imageMarker"
    end
  end
end
