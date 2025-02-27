class Management::CrowdfundingsController < Management::BaseController
  include HasOrders
  include CommentableActions

  before_action :only_verified_users, except: :print
  before_action :set_crowdfunding, only: [:vote, :show]
  before_action :parse_search_terms, only: :index
  before_action :load_categories, only: [:new, :edit]
  before_action :load_geozones, only: [:edit]

  has_orders %w{confidence_score hot_score created_at most_commented random}, only: [:index, :print]
  has_orders %w{most_voted newest}, only: :show

  def show
    super
    @notifications = @crowdfunding.notifications
    @related_contents = Kaminari.paginate_array(@crowdfunding.relationed_contents).page(params[:page]).per(5)

    redirect_to management_crowdfunding_path(@crowdfunding), status: :moved_permanently if request.path != management_crowdfunding_path(@crowdfunding)
  end

  def vote
    @crowdfunding.register_vote(managed_user, 'yes')
    set_crowdfunding_votes(@crowdfunding)
  end

  def print
    @crowdfundings = crowdfunding.send("sort_by_#{@current_order}").for_render.limit(5)
    set_crowdfunding_votes(@crowdfunding)
  end

  private

    def set_crowdfunding
      @crowdfunding = Crowdfunding.find(params[:id])
    end

    def crowdfunding_params
      params.require(:crowdfunding).permit(:title, :question, :summary, :description, :external_url, :video_url,
                                       :responsible_name, :tag_list, :terms_of_service, :geozone_id)
    end

    def resource_model
      Crowdfunding
    end

    def only_verified_users
      check_verified_user t("management.crowdfundings.alert.unverified_user")
    end

    def set_crowdfunding_votes(crowdfundings)
      @crowdfunding_votes = managed_user ? managed_user.crowdfunding_votes(crowdfundings) : {}
    end

    def set_comment_flags(comments)
      @comment_flags = managed_user ? managed_user.comment_flags(comments) : {}
    end

end
