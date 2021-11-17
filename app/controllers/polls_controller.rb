class PollsController < ApplicationController
  include PollsHelper
  include ServiceFlags

  include Gamification

  gamification :Poll


  service_flag :polls

  load_and_authorize_resource

  has_filters %w{current expired incoming}
  has_orders %w{most_voted newest oldest}, only: :show

  ::Poll::Answer # trigger autoload

  #aggiunta consultazioni breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.polls"), :polls_path

  def index
    @polls = @polls.by_user_pon.where(published: true).order(created_at: :desc).send(@current_filter).includes(:geozones).sort_for_list.page(params[:page])
  end

  def show
    @questions = @poll.questions.for_render.sort_for_list
    @token = poll_voter_token(@poll, current_user)
    @poll_questions_answers = Poll::Question::Answer.where(question: @poll.questions).where.not(description: "").order(:given_order)

    @answers_by_question_id = {}
    poll_answers = ::Poll::Answer.by_question(@poll.question_ids).by_author(current_user.try(:id))

    poll_answers.each do |answer|
      unless @answers_by_question_id[answer.question_id]
        @answers_by_question_id[answer.question_id] = Hash.new
      end
      @answers_by_question_id[answer.question_id][answer.answer] = answer.answer
    end
    @commentable = @poll
    @comment_tree = CommentTree.new(@commentable, params[:page], @current_order)

  end

  def social_flag
    @poll = Poll.find_by(id: params[:id])
    @poll.social_content.social_access = !@poll.social_content.social_access
    @poll.social_content.save
    @poll.touch
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def stats
    @stats = Poll::Stats.new(@poll).generate
  end

  def confirm
    if check_confirm
      redirect_to polls_path
      ::Poll::Answer.by_question(@poll.question_ids).by_author(current_user.try(:id)).update_all(submitted: true)
    else
      redirect_to poll_path(@poll), :flash => {:alert => "Non hai risposto ancora a tutte le domande obbligatorie"}
    end
  end

  def results
    @stats = Poll::Stats.new(@poll).generate
  end

  def download_result
    @stats = Poll::Stats.new(@poll).generate
    @polls = Poll
    @answer = Poll::Answer
    render template: 'polls/download_result.xlsx.axlsx', filename: "Risultatu.xlsx", disposition: 'inline'
  end

  def moderation_flag
    poll = Poll.find_by(id: params[:id])
    poll.moderation_flag = !poll.moderation_flag
    poll.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  private

  def check_confirm
    ids_q = @poll.questions.where("num_min_answers > 0").ids
    ids_q.each do |id|
      val = ::Poll::Answer.by_question(@poll.questions.where(id: id)).by_author(current_user.try(:id)).count
      if val < @poll.questions.where(id: id).first.num_min_answers
        return false
      end
    end
    return true      
  end

end



