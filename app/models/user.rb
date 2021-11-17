class User < ActiveRecord::Base
  include Merit
  has_merit


  include Verification

  if Rails.application.config.coord_user_address
    include Mappable #modifiche mappa
  else
    attr_accessor :skip_map
  end

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable,
         :trackable, :validatable, :omniauthable, :async, :password_expirable, :secure_validatable,
         authentication_keys: [:login]

  acts_as_booker
  acts_as_voter
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  include Graphqlable


  has_one :administrator
  has_one :moderator
  has_one :valuator
  has_one :manager
  has_one :gamification_result
  has_one :gamification_service_result

  has_one :sector

  has_many :st_sectors

  has_one :poll_officer, class_name: "Poll::Officer"
  has_one :organization
  has_one :lock
  has_many :flags
  has_many :identities, dependent: :destroy
  has_many :debates, -> { with_hidden }, foreign_key: :author_id
  has_many :proposals, -> { with_hidden }, foreign_key: :author_id
  has_many :crowdfundings, -> { with_hidden }, foreign_key: :author_id
  has_many :events, -> { with_hidden }, foreign_key: :author_id
  has_many :crowdfunding_rewards, -> { with_hidden }, foreign_key: :author_id

  has_many :agreements, -> { with_hidden }, foreign_key: :author_id


  has_many :reportings, -> { with_hidden }, foreign_key: :author_id #mia

  has_many :user_tags

  has_many :budget_investments, -> { with_hidden }, foreign_key: :author_id, class_name: 'Budget::Investment'
  has_many :comments, -> { with_hidden }
  has_many :spending_proposals, foreign_key: :author_id
  has_many :failed_census_calls
  has_many :notifications
  has_many :moderable_bookings, class_name: "BookingManager::ModerableBooking", foreign_key: "booker_id"
  has_many :direct_messages_sent, class_name: 'DirectMessage', foreign_key: :sender_id
  has_many :direct_messages_received, class_name: 'DirectMessage', foreign_key: :receiver_id
  has_many :legislation_answers, class_name: 'Legislation::Answer', dependent: :destroy, inverse_of: :user
  has_many :follows
  belongs_to :geozone
  belongs_to :pon
  has_many :votes, as: :voter, dependent: :destroy

  validates :username, presence: true, if: :username_required?
  validates :username, uniqueness: {scope: :registering_with_oauth}, if: :username_required?
  validates :document_number, uniqueness: {scope: :document_type}, allow_nil: true

  validate :validate_username_length
  validates :email, format: {with: Devise.email_regexp}, on: [:update, :create, :save]
  validates :official_level, inclusion: {in: 0..5}
  validates :terms_of_service, acceptance: {allow_nil: false}, on: :create

  validates_associated :organization, message: false

  accepts_nested_attributes_for :organization, update_only: true

  attr_accessor :skip_password_validation
  attr_accessor :use_redeemable_code
  attr_accessor :login
  attr_accessor :provider #attributo accessorio per controllare il tipo di accesso
  attr_reader :email_global_notifications_fields


  scope :by_user_pon, -> { where.not(virtual: true).where(pon_id: User.pon_id) }
  scope :normal_users, -> { where("users.id NOT IN (?)", administrators.select(:id)).where("users.id NOT IN (?)", moderators.select(:id)) }
  scope :same_pon_not_virtual, ->(pon_id) { where(virtual: false, pon_id: pon_id) }
  scope :administrators, -> { joins(:administrator) }
  scope :moderators, -> { joins(:moderator) }
  scope :organizations, -> { joins(:organization) }
  scope :officials, -> { where("official_level > 0") }
  scope :newsletter, -> { where(newsletter: true) }
  scope :for_render, -> { includes(:organization) }
  scope :by_document, ->(document_type, document_number) do
    where(document_type: document_type, document_number: document_number)
  end
  scope :email_digest, -> { where(email_digest: true) }
  scope :active, -> { where(erased_at: nil) }
  scope :erased, -> { where.not(erased_at: nil) }
  scope :public_for_api, -> { all }
  scope :by_comments, ->(query, topics_ids) { joins(:comments).where(query, topics_ids).uniq }
  scope :by_authors, ->(author_ids) { where("users.id IN (?)", author_ids) }
  scope :users_for_tag_preferences, ->(user_id) { joins(:user_tags)
                                                      .where(pon_id: User.pon_id).where.not(id: user_id)
                                                      .where("tag_id IN (?)", User.where(id: user_id).first().user_tags.pluck(:tag_id))
                                                      .order(id: :asc).pluck(:id).uniq }

  scope :by_username_email_or_document_number, ->(search_string) do
    string = "%#{search_string}%"
    #where("username ILIKE ? OR email ILIKE ? OR document_number ILIKE ?", string, string, string)
    where("username ILIKE ? OR email ILIKE ?", string, string)
  end

  before_validation :clean_document_number


  def is_social?
    self.provider == "facebook" || self.provider == "twitter" || self.provider == "google_oauth2"
  end

  def is_spid?
    self.provider == 'openam'
  end

  def self.system
    #recuperiamo l'utente system per il pon 5 (Bari)
    User.unscoped.where(virtual: true).where(pon_id: 5).where(username: 'sistema').first
  end

  def self.guest
    #recuperiamo l'utente guest per gli user investment anonimi
    User.unscoped.where(virtual: true).where(pon_id: 0).where(username: 'guest').first
  end

  def is_system
    if virtual == nil || virtual == false
      false
    else
      true
    end
  end


  def contents_created
    num_contents = debates.mod_approved.count +
        proposals.mod_approved.count +
        crowdfundings.mod_approved.count +
        events.mod_approved.count
    num_contents
  end


  def self.current=(user)
    Thread.current[:current_user] = user
  end

  def self.current
    @user = Thread.current[:current_user]
  end

  def self.pon_id=(id)
    Thread.current[:pon_id] = id
  end

  def self.pon_id
    @pon_id = Thread.current[:pon_id] ? Thread.current[:pon_id] : 0
  end

  def self.default_pon
    #@pon_id = 100
    @pon_id = 5
  end

  # Get the existing user by email if the provider gives us a verified email.
  def self.first_or_initialize_for_oauth(auth)

    oauth_email = auth.info.email
    oauth_email_confirmed = oauth_email.present?
    oauth_user = User.find_by(email: oauth_email) if oauth_email_confirmed

    uname = auth.info.name

    cod_fiscale = ""
    if auth.provider.to_s == 'openam'
      uname = auth.extra.raw_info.givenName[0].capitalize + " " + auth.info.last_name.capitalize
      cod_fiscale = defined?(auth.extra.raw_info.fiscalNumber[0]) ? auth.extra.raw_info.fiscalNumber[0] : ""
    end

    if auth.provider.to_s == 'shibboleth'
      uname += ' ' + auth.info.last_name
    end

    accountToUpd = oauth_user || User.new(
        username: uname || auth.uid,
        email: oauth_email,
        cod_fiscale: cod_fiscale,
        oauth_email: oauth_email,
        password: Devise.friendly_token[0, 20],
        terms_of_service: '1',
        confirmed_at: oauth_email_confirmed ? DateTime.current : nil
    )
  end

  def name
    organization? ? organization.name : username
  end

  def event_votes(events)
    voted = votes.for_events(Array(events).map(&:id))
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def debate_votes(debates)
    voted = votes.for_debates(Array(debates).map(&:id))
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def proposal_votes(proposals)
    voted = votes.for_proposals(Array(proposals).map(&:id))
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end


  def crowdfunding_votes(crowdfundings)
    voted = votes.for_crowdfundings(Array(crowdfundings).map(&:id))
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  #mia
  def reporting_votes(reportings)
    voted = votes.for_reportings(Array(reportings).map(&:id))
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def legislation_proposal_votes(proposals)
    voted = votes.for_legislation_proposals(proposals)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def spending_proposal_votes(spending_proposals)
    voted = votes.for_spending_proposals(spending_proposals)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def budget_investment_votes(budget_investments)
    voted = votes.for_budget_investments(budget_investments)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def comment_flags(comments)
    comment_flags = flags.for_comments(comments)
    comment_flags.each_with_object({}) { |f, h| h[f.flaggable_id] = true }
  end

  def voted_in_group?(group)
    votes.for_budget_investments(Budget::Investment.where(group: group)).exists?
  end

  def can_moderate?
    administrator? || moderator?
  end

  def can_sector_content?
    Sector.where("user_id = ?", id).where(visible: true).count > 0
  end


  def administrator?
    administrator.present?
  end

  def moderator?
    moderator.present?
  end

  def can_create?
    #pon_id == User.pon_id
    #abilitiamo la creazione di contenuti indipendentemente dal PON di appartenenza
    true
  end

  def valuator?
    valuator.present?
  end

  def manager?
    manager.present?
  end

  def sector?
    sector.present?
  end

  def poll_officer?
    poll_officer.present?
  end

  def organization?
    organization.present?
  end

  def verified_organization?
    organization && organization.verified?
  end

  def official?
    official_level && official_level > 0
  end

  def add_official_position!(position, level)
    return if position.blank? || level.blank?
    update official_position: position, official_level: level.to_i
  end

  def remove_official_position!
    update official_position: nil, official_level: 0
  end

  def has_official_email?
    domain = Setting['email_domain_for_officials', self.pon_id]
    email.present? && ((email.end_with? "@#{domain}") || (email.end_with? ".#{domain}"))
  end

  def display_official_position_badge?
    return true if official_level > 1
    official_position_badge? && official_level == 1
  end

  def block
    debates_ids = Debate.where(author_id: id).pluck(:id)
    comments_ids = Comment.where(user_id: id).pluck(:id)
    proposal_ids = Proposal.where(author_id: id).pluck(:id)
    process_ids = ::Legislation::Process.where(author_id: id).pluck(:id)
    agreements_ids = ::Collaboration::Agreement.where(author_id: id).pluck(:id)
    reporting_ids = Reporting.where(author_id: id).pluck(:id) #mia
    legislation_proposal_ids = ::Legislation::Proposal.where(author_id: id).pluck(:id)
    event_ids = Event.where(author_id: id).pluck(:id)
    crowdfunding_ids = Crowdfunding.where(author_id: id).pluck(:id)


    Debate.hide_all debates_ids
    Comment.hide_all comments_ids
    Proposal.hide_all proposal_ids
    Crowdfunding.hide_all crowdfunding_ids
    Event.hide_all event_ids
    Reporting.hide_all reporting_ids #mia
    ::Legislation::Process.hide_all process_ids
    ::Legislation::Proposal.hide_all legislation_proposal_ids


    hide

  end

  def erase(erase_reason = nil)
    update(
        erased_at: Time.current,
        erase_reason: erase_reason,
        username: nil,
        email: nil,
        unconfirmed_email: nil,
        phone_number: nil,
        encrypted_password: "",
        confirmation_token: nil,
        reset_password_token: nil,
        email_verification_token: nil,
        confirmed_phone: nil,
        unconfirmed_phone: nil,
        #altri dati cancellati
        document_number: nil,
        document_type: nil,
        residence_verified_at: nil,
        cod_fiscale: nil
    )
    identities.destroy_all
  end

  def erased?
    erased_at.present?
  end

  def take_votes_if_erased_document(document_number, document_type)
    erased_user = User.erased.where(document_number: document_number)
                      .where(document_type: document_type).first
    if erased_user.present?
      take_votes_from(erased_user)
      erased_user.update(document_number: nil, document_type: nil)
    end
  end

  def take_votes_from(other_user)
    return if other_user.blank?
    Poll::Voter.where(user_id: other_user.id).update_all(user_id: id)
    Budget::Ballot.where(user_id: other_user.id).update_all(user_id: id)
    Vote.where("voter_id = ? AND voter_type = ?", other_user.id, "User").update_all(voter_id: id)
    data_log = "id: #{other_user.id} - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
    update(former_users_data_log: "#{former_users_data_log} | #{data_log}")
  end

  def locked?
    Lock.find_or_create_by(user: self).locked?
  end

  def self.search(term)
    term.present? ? where("email = ? OR username ILIKE ?", term, "%#{term}%") : none
  end

  def self.username_max_length
    @@username_max_length ||= columns.find { |c| c.name == 'username' }.limit || 60
  end

  def self.minimum_required_age
    (Setting['min_age_to_participate', self.pon_id] || 16).to_i
  end

  def show_welcome_screen?
    sign_in_count == 1 && unverified? && !organization && !administrator?
  end

  def password_required?
    return false if skip_password_validation
    super
  end

  def username_required?
    !organization? && !erased?
  end

  def email_required?
    !erased? && unverified?
  end

  def locale
    self[:locale] ||= I18n.default_locale.to_s
  end

  def confirmation_required?
    super && !registering_with_oauth
  end

  def send_oauth_confirmation_instructions
    if oauth_email != email
      update(confirmed_at: nil)
      send_confirmation_instructions
    end
    update(oauth_email: nil) if oauth_email.present?
  end

  def name_and_email
    "#{name} (#{email})"
  end

  def age
    Age.in_years(date_of_birth)
  end

  def save_requiring_finish_signup
    begin
      self.registering_with_oauth = true
      save(validate: false)
        # Devise puts unique constraints for the email the db, so we must detect & handle that
    rescue ActiveRecord::RecordNotUnique
      self.email = nil
      save(validate: false)
    end
    true
  end

  def ability
    @ability ||= Ability.new(self)
  end

  delegate :can?, :cannot?, to: :ability

  def public_proposals
    public_activity? ? proposals : User.none
  end

  def public_crowdfundings
    public_activity? ? crowdfundings : User.none
  end

  def public_agreements
    public_activity? ? agreements : User.none
  end

  #mia
  def public_reportings
    public_activity? ? reportings : User.none
  end

  def public_debates
    public_activity? ? debates : User.none
  end

  def public_events
    public_activity? ? events : User.none
  end

  def public_comments
    public_activity? ? comments : User.none
  end

  # overwritting of Devise method to allow login using email OR username
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions.to_hash).where(["lower(email) = ?", login.downcase]).first ||
        where(conditions.to_hash).where(["username = ?", login]).first
  end

  def interests
    follows.map { |follow| follow.followable.tags.map(&:name) }.flatten.compact.uniq
  end

  def set_sector_for_user()
    sector_sel = Sector.where(cf_rappr_legale: cod_fiscale).all
    sector_sel.each do |single|
      single.crea_relation_sector(self)
    end

    sector_sel = StSector.where(cf_rappr_legale: cod_fiscale).all
    sector_sel.each do |single|
      single.crea_relation_sector(self)
    end

  end


  # Cicla tra i campi che devono essere inclusi dall'opzione globale per
  # accendere e spegnere le notifiche email effettuando un AND logico.
  # Restituirà true solo se tutte le opzioni sono a `true`, altrimenti restituirà `false`
  def email_global_notifications

    result = true

    self.email_global_notifications_fields.each do |field_name|
      result = (result and eval('self.' + field_name))
    end

    result

  end

  def email_global_notifications_fields
    %w[email_on_comment email_on_comment_reply]
  end

  private

  def clean_document_number
    return unless document_number.present?
    self.document_number = document_number.gsub(/[^a-z0-9]+/i, "").upcase
  end

  def validate_username_length
    validator = ActiveModel::Validations::LengthValidator.new(
        attributes: :username,
        maximum: User.username_max_length)
    validator.validate(self)
  end

end
