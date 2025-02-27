class Legislation::Annotation < ActiveRecord::Base
  include Documentable
  documentable max_documents_allowed: 2,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  include Imageable
  imageable max_images_allowed: 2


  COMMENTS_PAGE_SIZE = 5
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  serialize :ranges, Array

  belongs_to :draft_version, class_name: 'Legislation::DraftVersion', foreign_key: 'legislation_draft_version_id'
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  has_many :comments, as: :commentable, dependent: :destroy

  validates :text, presence: true
  validates :quote, presence: true
  validates :draft_version, presence: true
  validates :author, presence: true

  before_save :store_range, :store_context
  after_create :create_first_comment

  def store_range
    self.range_start = ranges.first["start"]
    self.range_start_offset = ranges.first["startOffset"]
    self.range_end = ranges.first["end"]
    self.range_end_offset = ranges.first["endOffset"]
  end

  def store_context
    begin
      html = draft_version.body_html
      doc = Nokogiri::HTML(html)

      selector_start = "/html/body/#{range_start}"
      el_start = doc.at_xpath(selector_start)

      selector_end = "/html/body/#{range_end}"
      el_end = doc.at_xpath(selector_end)

      remainder_el_start = el_start.text[0 .. range_start_offset - 1] unless range_start_offset.zero?
      remainder_el_end = el_end.text[range_end_offset .. -1]

      self.context = "#{remainder_el_start}<span class=annotator-hl>#{quote}</span>#{remainder_el_end}"
    rescue
      "<span class=annotator-hl>#{quote}</span>"
    end
  end

  def create_first_comment
    comments.create(body: text, user: author)
  end

  def title
    text[0..50]
  end

  def weight
    comments_count + comments.sum(:cached_votes_total)
  end
end
