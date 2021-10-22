class Moderation::UsersController < Moderation::BaseController

  before_action :load_users, only: :index

  load_and_authorize_resource

  def index
  end

  def hide_in_moderation_screen
    block_user

    redirect_to request.query_parameters.merge(action: :index), notice: I18n.t('moderation.users.notice_hide')
  end

  def hide
    block_user
    commentable = Comment.where(id: params[:resource]).first.commentable
    
    redirect_to url_for(commentable),notice: I18n.t('moderation.users.notice_hide')
  end

  private

    def load_users
      @users = User.by_user_pon.with_hidden.search(params[:name_or_email]).page(params[:page]).for_render
    end

    def block_user
      @user.block
      Activity.log(current_user, :block, @user)
    end

end