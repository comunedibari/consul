class Administrator < ActiveRecord::Base
  belongs_to :user, touch: true
  delegate :name, :email, :name_and_email, to: :user

  validates :user_id, presence: true, uniqueness: true

  default_scope { User.pon_id>0? joins(:user).where("users.pon_id = ?", User.pon_id) : all }


end
