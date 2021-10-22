class RenamePriceInLegislationProcessWorksTable < ActiveRecord::Migration

  def up
    rename_column :legislation_process_works, :price, :price_num
    add_column :legislation_process_works, :price, :string
    Legislation::ProcessWork.update_all ["price = price_num::text"]
  end

  def down
    remove_column :legislation_process_works, :price
    rename_column :legislation_process_works, :price_num, :price
  end
  
end