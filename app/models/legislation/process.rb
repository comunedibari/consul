class Legislation::Process < ActiveRecord::Base

  include Rails.application.routes.url_helpers
  include Flaggable
  include Taggable
  include Conflictable
  include Measurable
  include Sanitizable
  include Searchable
  include Filterable
  include HasPublicAuthor
  include Graphqlable
  include Followable
  #include Communitable
  include Imageable
  include Mappable
  include Notifiable
  include Documentable
  include Galleryable
  include ActsAsParanoidAliases
  include EmbedVideosHelper
  include Relationable
  include Moderable
  include Sectorable
  include Eventable
  include Sociable


  documentable max_documents_allowed: 3,
               max_file_size: 15.megabytes #,
  #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
  #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")

  imageable max_images_allowed: 20

  acts_as_paranoid column: :hidden_at
  belongs_to :geozone
  belongs_to :pon
  belongs_to :legislation_process_typology, :class_name => 'Legislation::ProcessTypology', :foreign_key => 'legislation_process_typologies_id'
  PHASES_AND_PUBLICATIONS = %i(debate_phase allegations_phase proposals_phase draft_publication result_publication).freeze

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  validates :author, presence: true
  has_many :draft_versions, -> { order(:id) }, class_name: 'Legislation::DraftVersion',
           foreign_key: 'legislation_process_id', dependent: :destroy
  has_one :final_draft_version, -> { where final_version: true, status: 'published' }, class_name: 'Legislation::DraftVersion',
          foreign_key: 'legislation_process_id'
  has_many :questions, -> { order(:id) }, class_name: 'Legislation::Question', foreign_key: 'legislation_process_id', dependent: :destroy
  has_many :proposals, -> { order(:id) }, class_name: 'Legislation::Proposal', foreign_key: 'legislation_process_id', dependent: :destroy
  has_one :process_work, class_name: 'Legislation::ProcessWork', foreign_key: 'legislation_process_id'
  has_one :process_chance, class_name: 'Legislation::ProcessChance', foreign_key: 'legislation_process_id'


  has_one :process_sgap, class_name: 'Legislation::ProcessSgap', foreign_key: 'legislation_process_id'
  has_many :process_phases, -> { order(:id) }, class_name: 'Legislation::ProcessPhase', foreign_key: 'legislation_process_id', dependent: :destroy
  has_many :process_finance, -> { order(:id) }, class_name: 'Legislation::ProcessFinance', foreign_key: 'legislation_process_id', dependent: :destroy

  has_one :sector_content, as: :sectorable, dependent: :destroy


  accepts_nested_attributes_for :process_work, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :process_chance, allow_destroy: true, reject_if: :all_blank
  validates :title, presence: true
  #validates :description, presence: true, length: { maximum: Collaboration::Agreement.description_max_length }
  validate :valid_description
  validates :start_date, presence: true
  validates :end_date, presence: true
  #validate :valid_end_date

  #validates :debate_start_date, presence: true, if: :debate_end_date?
  #validates :debate_end_date, presence: true, if: :debate_start_date?
  validates :allegations_start_date, presence: true, if: :allegations_end_date?
  validates :allegations_end_date, presence: true, if: :allegations_start_date?
  validates :proposals_phase_end_date, presence: true, if: :proposals_phase_start_date?
  validate :valid_date_ranges

  #tipologie di process alternative
  scope :process_standard, -> { where('process_type in (1)') }
  scope :process_work, -> { where('process_type in (2,4)') } #.where("visible= ? ", true)
  scope :process_chance, -> { where('process_type in (3,5)') } #.where("visible= ? ", true)
  scope :process_chance_edit, -> { where('process_type in (3,5)') } #.where("visible= ? ", true)
  scope :visibles, -> { where("visible= ? ", true) }

  #scope :opens, -> { where("start_date <= ? and end_date >= ?", Date.current, Date.current).order('id DESC') }
  scope :opens, -> {
    joins("left join legislation_process_chances on legislation_process_chances.legislation_process_id = legislation_processes.id")
        .joins("left join legislation_process_works on legislation_process_works.legislation_process_id = legislation_processes.id")
        .where("(legislation_processes.process_type = 5 and legislation_process_chances.progress_status != '100') or legislation_process_works.work_status != 'Chiuso' or (legislation_processes.process_type = 1 and legislation_processes.start_date <= Now() and legislation_processes.end_date >= Now() and legislation_process_works.work_status is null) or (legislation_processes.process_type = 3 and legislation_processes.start_date <= Now() and legislation_processes.end_date >= Now() )").order('id DESC')
  }

  #scope :past, -> { where("end_date < ?", Date.current).order('id DESC') }
  scope :past, -> {
    joins("left join legislation_process_chances on legislation_process_chances.legislation_process_id = legislation_processes.id")
        .joins("left join legislation_process_works on legislation_process_works.legislation_process_id = legislation_processes.id")
        .where("(legislation_processes.process_type = 5 and legislation_process_chances.progress_status = '100') or legislation_process_works.work_status = 'Chiuso' or (legislation_processes.process_type = 1 and legislation_processes.end_date < Now() and legislation_process_works.work_status is null) or (legislation_processes.process_type = 3 and legislation_processes.end_date < Now())").order('id DESC') }
  #start_date <= ? and end_date >= ?", Date.current, Date.current).order('id DESC') }

  scope :next, -> { where("start_date > ?", Date.current).order('id DESC') }

  scope :bis, -> { where(process_type: 5).order('id DESC') }
  scope :sgap, -> { where(process_type: 4).order('id DESC') }

  scope :planned, -> { where("start_date > ?", Date.current).order('id DESC') }

  scope :waiting_moderation, -> { where("moderation_entity = 2").order('id DESC') }

  scope :process_type, ->(process_type_list) { where("process_type in (?)", process_type_list) }

  scope :process_all_type, -> { where('process_type in (1,2,3)') }

  scope :published, -> { where(published: true) }

  scope :for_render, -> { includes(:tags) }
  scope :featured, -> {}
  scope :by_user_pon, -> { where(pon_id: User.pon_id) }
  scope :by_user, ->(user) { where(author: user).where('moderation_entity in (1,2)') }
  scope :sort_by_process_type, -> { reorder(process_type: :desc) }
  scope :sort_by_confidence_score, -> { reorder(confidence_score: :desc) }
  scope :sort_by_created_at, -> { reorder(created_at: :desc) }
  scope :sort_by_start_date, -> { reorder(start_date: :desc) }
  scope :sort_by_random, -> { reorder("RANDOM()") }
  scope :sort_by_relevance, -> { all }
  scope :sort_by_recommendations, -> {}
  scope :last_week, -> { where("created_at >= ?", 7.days.ago) }
  scope :public_for_api, -> { all.mod_approved }
  scope :filter_by_typology, ->(typology_id_array) { where(legislation_process_typologies_id: typology_id_array) }
  #miaa
  #def index
  #logger.debug "M O D E L *****************"
  #logger.debug "TIPO = "+ @process.process_type.to_s

  #end
=begin
  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id titolo descrizione data_inizio_lavori data_fine_lavori municipalità zona latitudine longitudine costo_lavori finanziamento stato_lavori indirizzo informazioni_di_contatto avanzamento_finanziamento avanzamento_progetto avanzamento_gara avanzamento_realizzazione}
      all.each do |e|
        csv << [
          e.id,
          e.title,
          e.description,
          e.start_date.strftime('%Y-%m-%d %H:%M:%S'),
          e.end_date.strftime('%Y-%m-%d %H:%M:%S'),
          e.pon.name,
          e.geozone ? e.geozone.name : nil,
          e.map_location ? e.map_location.latitude : nil,
          e.map_location ? e.map_location.longitude : nil,
          e.process_work.price ? e.process_work.price : "-",
          e.process_work.financing ? e.process_work.financing : "-",
          e.process_work.work_status ? e.process_work.work_status : "-",
          e.process_work.address ? e.process_work.address : "-",
          e.process_work.contacts ? e.process_work.contacts : "-",
          e.process_work.financing_perc ? e.process_work.financing_perc : "-",
          e.process_work.project_perc ? e.process_work.project_perc : "-",
          e.process_work.competition_perc ? e.process_work.competition_perc : "-",
          e.process_work.realizzation_perc ? e.process_work.realizzation_perc : "-",
        ]
      end
    end
  end
=end
  def editable_by?(user)
    if process_type == 4 # || process_type == 5
      false
    else
      author_id == user.id || (user.administrator? && user.pon_id == self.pon_id)
    end
  end

  def moderable_comments_by?(user)
    user && user.pon_id==self.pon_id && user.can_moderate?
  end

  def self.recommendations(user)
    tagged_with(user.interests, any: true)
        .where("author_id != ?", user.id)
  end

  def self.processes_orders(user)
    orders = %w{process_type hot_score confidence_score created_at relevance}
    orders << "recommendations" if user.present?
    orders
  end

  def to_param
    "#{id}-#{title}".parameterize
  end

  def debate_phase
    Legislation::Process::Phase.new(debate_start_date, debate_end_date, debate_phase_enabled)
  end

  def allegations_phase
    Legislation::Process::Phase.new(allegations_start_date, allegations_end_date, allegations_phase_enabled)
  end

  def proposals_phase
    Legislation::Process::Phase.new(proposals_phase_start_date, proposals_phase_end_date, proposals_phase_enabled)
  end

  def draft_publication
    Legislation::Process::Publication.new(draft_publication_date, draft_publication_enabled)
  end

  def result_publication
    Legislation::Process::Publication.new(result_publication_date, result_publication_enabled)
  end

  def enabled_phases_and_publications_count
    PHASES_AND_PUBLICATIONS.count { |process| send(process).enabled? }
  end

  def total_comments
    questions.sum(:comments_count) + draft_versions.map(&:total_comments).sum
  end

  def status
    today = Date.current

    if in_approval?
      :waiting_approval
    elsif today < start_date
      :planned
    elsif end_date < today
      :closed
    else
      :open
    end
  end

  def searchable_values
    {title => 'A',
     #author.username    => 'B',
     tag_list.join(' ') => 'B',
     #geozone.try(:name) => 'B',
     description => 'D',
    }
  end

  def self.search(terms)
    pg_search(terms)
  end

  def after_hide
    tags.each { |t| t.decrement_custom_counter_for('Legislation::Process') }
  end

  def after_restore
    tags.each { |t| t.increment_custom_counter_for('Legislation::Process') }
  end

  def service_flag_name
    if process_type == 3 || process_type == 5
      "chances"
    elsif process_type == 2 || process_type == 4
      "works"
    elsif process_type == 1
      "processes"
    end
  end

  def processes_proposal_creable_by?(user)
    social_service = Setting.where(key: 'service_social.legislation_process_processes_proposal').where("value = 'true' ").where(pon_id: user.pon_id).first
    if !user.can_create?
      return false
    end
    if (user.provider.present? && user.is_social? && !social_service) || user.administrator?
      return false
    end

    return true
  end

  private

  def valid_end_date
    if process_type != 1
      errors.add(:end_date, :blank) if !end_date
    end
  end

  def valid_date_ranges
    #if process_type != 1
    errors.add(:end_date, :invalid_date_range) if end_date && start_date && end_date < start_date
    #end
    #errors.add(:debate_end_date, :invalid_date_range) if debate_end_date && debate_start_date && debate_end_date < debate_start_date
    if allegations_end_date && allegations_start_date && allegations_end_date < allegations_start_date
      errors.add(:allegations_end_date, :invalid_date_range)
    end
  end

  def valid_description
    errors.add(:description, :blank) if process_type != 4 && (!description or description.strip == '')
  end

end
