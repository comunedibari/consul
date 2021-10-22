class Admin::Poll::PollsController < Admin::Poll::BaseController
  include Eventify
  load_and_authorize_resource

  before_action :load_search, only: [:search_booths, :search_officers]
  before_action :load_geozones, only: [:new, :create, :edit, :update]

  def index
    @polls = Poll.by_user_pon
  end

  def show
    @poll = Poll.includes(:questions).
                          order('poll_questions.title').
                          find(params[:id])
  end

  def new
  end

  def create
    @poll = Poll.new(poll_params.merge(author: current_user, pon_id: User.pon_id))
    if @poll.save
      social_service = Setting.find_by(key: 'service_social.polls',pon_id: User.pon_id).value 
      SocialContent.create(sociable: @poll, social_access:  social_service)

      redirect_to [:admin, @poll], notice: t("flash.actions.create.poll")
    else
      render :new
    end
  end

  def edit
  end


  def update
    if @poll.update(poll_params)
      if @poll.published
        if @poll.event_content.present?
          update_event(@poll)
        else 
          create_as_event(@poll)
        end
      else 
        destroy_event(@poll)
      end
      redirect_to [:admin, @poll], notice: t("flash.actions.update.poll")
    else
      render :edit
    end
  end

  def add_question
    question = ::Poll::Question.find(params[:question_id])

    if question.present?
      @poll.questions << question
      notice = t("admin.polls.flash.question_added")
    else
      notice = t("admin.polls.flash.error_on_question_added")
    end
    redirect_to admin_poll_path(@poll), notice: notice
  end

  def booth_assignments
    @polls = Poll.current_or_incoming
  end

  private

    def load_geozones
      @geozones = Geozone.all.order(:name)
    end

    def poll_params
      images_attributes = [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy]
      attributes = [:name, :starts_at, :ends_at, :geozone_restricted, :summary, :description,:published,
                    :results_enabled, :stats_enabled, geozone_ids: [],
                    images_attributes: images_attributes]
      params.require(:poll).permit(*attributes)
    end

    def search_params
      params.permit(:poll_id, :search)
    end

    def load_search
      @search = search_params[:search]
    end

end
