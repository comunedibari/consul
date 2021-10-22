class Admin::Poll::QuestionsController < Admin::Poll::BaseController
  include CommentableActions

  load_and_authorize_resource :poll
  load_and_authorize_resource :question, class: 'Poll::Question'
  #respond_to :html, :js





  
  def index
    @polls = Poll.by_user_pon
    @search = search_params[:search]

    @questions = @questions.by_user_pon.search(search_params).page(params[:page]).order("created_at DESC")

    @proposals = Proposal.successful.sort_by_confidence_score
  end

  def new
    @polls = Poll.by_user_pon
    proposal = Proposal.find(params[:proposal_id]) if params[:proposal_id].present?
    @question.copy_attributes_from_proposal(proposal)
    @num_max_answers_select_options = {}
    @num_max_answers_select_options.store("0", "0")
    @num_min_answers_select_options = {}
    @num_min_answers_select_options.store("0", "0")
    @num_min_answers_select_options.store("1", "1")
    
  end

  def create
    @question.author = @question.proposal.try(:author) || current_user

    if @question.save
      redirect_to admin_question_path(@question)
    else
      render :new
    end
  end

  def show
   if @question && @question.pon_id != current_user.pon_id
    raise CanCan::AccessDenied
   end   
  end

  def edit
    
    @num_min_answers_select_options = (0..1).step(1).to_a.map{|s| ["#{s}", s]} + (2..@question.question_answers.count).step(1).to_a.map{|s| ["#{s}", s]}
    @num_max_answers_select_options = (0..@question.question_answers.count).step(1).to_a.map{|s| ["#{s}", s]}
  end

  def update
    if @question.update(question_params)
      redirect_to admin_question_path(@question), notice: t("flash.actions.update.question")
    else
      render :edit
    end
  end

  def destroy
    if @question.destroy
      notice = t("flash.actions.destroy.question")
    else
      notice = t("flash.actions.destroy.error")
    end
    redirect_to admin_questions_path, notice: notice
  end

  def load_question
    @quetions = Poll.by_user_pon
    @selected = params[:poll_id]
    render :partial => 'load_question', :locals => {:selected => params[:poll_id]} #, :layout => false    
    #respond_to do |format|
    #  format.js do
    #    render :partial => 'load_question', :locals => {:selected => params[:poll_id]}, :layout => false    
    #  end
    #end
  end

  private

    def question_params
      params.require(:poll_question).permit(:poll_id, :title, :question,:proposal_id, :video_url, :num_max_answers, :num_min_answers,
                                            images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                            documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy]
                                            )
    end

    def search_params
      params.permit(:poll_id, :search)
    end

end
