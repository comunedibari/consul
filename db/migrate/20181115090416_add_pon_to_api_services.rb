class AddPonToApiServices < ActiveRecord::Migration
  def change
    add_reference :api_services, :pon, index: true, foreign_key: true, null:false, default: 5
  end
end
