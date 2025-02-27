class SignatureSheet < ActiveRecord::Base
  belongs_to :signable, polymorphic: true
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'

  VALID_SIGNABLES = %w(Proposal Crowdfunding Reporting Budget::Investment SpendingProposal) #miaa

  has_many :signatures

  validates :author, presence: true
  validates :signable_type, inclusion: {in: VALID_SIGNABLES}
  validates :document_numbers, presence: true
  validates :signable, presence: true
  validate  :signable_found

  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}

  def name
    "#{signable_name} #{signable_id}"
  end

  def signable_name
    I18n.t("activerecord.models.#{signable_type.underscore}", count: 1)
  end

  def verify_signatures
    parsed_document_numbers.each do |document_number|
      signature = signatures.where(document_number: document_number).first_or_create
      signature.verify
    end
    update(processed: true)
  end

  def parsed_document_numbers
    document_numbers.split(/\r\n|\n|[,]/).collect {|d| d.gsub(/\s+/, '') }
  end

  def signable_found
    errors.add(:signable_id, :not_found) if errors.messages[:signable].present?
  end
end
