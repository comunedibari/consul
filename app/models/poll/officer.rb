class Poll
  class Officer < ActiveRecord::Base
    belongs_to :user
    has_many :officer_assignments, class_name: "Poll::OfficerAssignment"
    has_many :shifts, class_name: "Poll::Shift"
    has_many :failed_census_calls, foreign_key: :poll_officer_id

    validates :user_id, presence: true, uniqueness: true

    delegate :name, :email, to: :user

    default_scope { User.pon_id>0? joins(:user).where("users.pon_id = ?", User.pon_id) : all }

    scope :by_pon_id,    ->(pon_id) { includes(:user).where(:users => {:pon_id =>  pon_id}) }

    def voting_days_assigned_polls
      officer_assignments.voting_days.includes(booth_assignment: :poll).
                               map(&:booth_assignment).
                               map(&:poll).uniq.compact.
                               sort {|x, y| y.ends_at <=> x.ends_at}
    end

    def final_days_assigned_polls
      officer_assignments.final.includes(booth_assignment: :poll).
                               map(&:booth_assignment).
                               map(&:poll).uniq.compact.
                               sort {|x, y| y.ends_at <=> x.ends_at}
    end

  end
end
