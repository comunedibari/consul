class ChangeColumnNameInPons < ActiveRecord::Migration
  def change
    rename_column :pons, :census_code, :cod_belfiore
  end
end
