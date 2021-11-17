class RenameCrmToSondaggioEsterno < ActiveRecord::Migration
  def change
    rename_column :polls, :ext_use, :sondaggio_esterno
  end
end
