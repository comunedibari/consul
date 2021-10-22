class Admin::Sectors < ActiveRecord::Base
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}

  belongs_to :pon
end
