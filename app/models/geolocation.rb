class Geolocation < ActiveRecord::Base

  #mia (aggiunto reporting)
  LOCALIZABLE_TYPES = %w(User Proposal Reporting Debate Crowdfunding Budget::Investment Poll Topic Legislation::Question
                        Legislation::Annotation Legislation::Proposal).freeze

  belongs_to :localizable, -> { with_hidden }, polymorphic: true

  validates :localizable_type, inclusion: { in: LOCALIZABLE_TYPES }


  def json_data
    {
      localizable_id: localizable_id,
      localizable_type: localizable_type,
      lat: lat,
      long: long
    }
  end

end
