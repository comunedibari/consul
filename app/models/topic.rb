class Topic < ActiveRecord::Base
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases
  include Notifiable
  include Documentable
  documentable max_documents_allowed: 2,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  include Imageable
  imageable max_images_allowed: 4

  belongs_to :community
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'

  has_many :comments, as: :commentable

  validates :title, presence: true
  validates :description, presence: true
  validates :author, presence: true

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :sort_by_most_commented, -> { reorder(comments_count: :desc) }

end
