class CommentTree

  ROOT_COMMENTS_PER_PAGE = 10

  attr_accessor :root_comments, :comments, :commentable, :page, :order

  def initialize(commentable, page, order = 'confidence_score', valuations: false)
    @commentable = commentable
    @page = page
    @order = order
    @valuations = valuations
    @comments = root_comments + root_descendants
  end

  def root_comments
    base_comments.roots.send("sort_by_#{order}").page(page).per(ROOT_COMMENTS_PER_PAGE).for_render
  end

  def base_comments
    if @valuations && commentable.respond_to?('valuations')
      commentable.valuations
    else
      commentable.comments.where("moderation_entity in (1) or moderation_entity is NULL")
    end
  end

  def root_descendants
    root_comments.each_with_object([]) do |root, array|
      array.concat(Comment.where("moderation_entity in (1) or moderation_entity is NULL").descendants_of(root).send("sort_descendants_by_#{order}").for_render.to_a)
    end
  end

  def ordered_children_of(parent)
    comments_by_parent_id[parent.id] || []
  end

  def comments_by_parent_id
    comments.each_with_object({}) do |comment, array|
      (array[comment.parent_id] ||= []) << comment
    end
  end

  def comment_authors
    comments.map(&:author)
  end
end
