class Moderator < ActiveRecord::Base
  belongs_to :user, touch: true
  delegate :name, :email, to: :user

  validates :user_id, presence: true, uniqueness: true
  default_scope { User.pon_id>0? joins(:user).where("users.pon_id = ?", User.pon_id) : all }

end
