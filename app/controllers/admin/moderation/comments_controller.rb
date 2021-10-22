class Admin::Moderation::CommentsController < Admin::BaseController
  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}

  before_action :load_comment, only: [:confirm_hide, :restore]

  def index
    @comments = Comment.by_comment_pon.not_valuations.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @comment.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    if (@comment.flags_count == 0)
      logger.info "--------------invia notifica"
    else
      logger.info "--------------non invia notifica"
    end
    @comment.restore
    @comment.ignore_flag
    Activity.log(current_user, :restore, @comment)
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

    def load_comment
      @comment = Comment.by_comment_pon.not_valuations.find(params[:id])
    end

end
