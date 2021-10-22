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
    
    @token = cookies[:token].nil? ? poll_voter_token(@poll, current_user) : cookies[:token]

    if !cookies[:token].nil? 
      cookies.delete :token
    end
    
    if @token == ""
      @token = generate_token
    end

    if current_user
      check_answers @token, current_user.id
    end

    @poll_questions_answers = Poll::Question::Answer.where(question: @poll.questions).where.not(description: "").order(:given_order)

    @answers_by_question_id = {}
    if current_user.nil?
      tmp_user = User.guest
    else
      tmp_user = current_user
    end
    poll_answers = ::Poll::Answer.by_question(@poll.question_ids).by_author(tmp_user.try(:id)).by_token(@token)

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
    token = params[:token]

    if current_user.nil?
      tmp_user = User.guest
    else
      tmp_user = current_user
    end

    check_answers token, tmp_user.id
    if check_confirm token, tmp_user.id
      if current_user.nil?
        cookies.permanent["Poll#{@poll.id}"] = token
      end
      redirect_to polls_path, notice: t('notice.operaction_successfull')
      ::Poll::Answer.by_question(@poll.question_ids).by_author(tmp_user.id).where(token: token).update_all(submitted: true)
      ::Poll::Voter.where(poll_id: @poll.id).where(user_id: tmp_user.id).where(token: token).where(confirmed: false).first.update(confirmed: true)
    else
      cookies[:token] = token
      redirect_to poll_path(@poll), :flash => {:alert => "Non hai risposto ancora a tutte le risposte obbligatorie"}      
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

  def check_confirm token, id_user
    ids_q = @poll.questions.where.not(title: "----").where("num_min_answers > 0").order(:id).ids
    ids_q.each do |id|
      #val = ::Poll::Answer.by_question(@poll.questions.where(id: id)).by_author(current_user.try(:id)).where(token: token).count
      val = ::Poll::Answer.by_question(@poll.questions.where(id: id)).by_author(id_user).where(token: token).count
      if val < @poll.questions.where(id: id).first.num_min_answers
        question= @poll.questions.where(id: id).first
        if (question.poll_question_type_id != 3)
          return false
        else
          #answers_opt = ::Poll::Answer.by_question(question.question_optional_id).by_author(current_user.try(:id)).where(token: token)
          answers_opt = ::Poll::Answer.by_question(question.question_optional_id).by_author(id_user).where(token: token)
          flag = true
          answers_opt.each do |answer|
            if answer.answer == question.poll_question_answer.title
              flag = false
            end
          end
          if !flag
            return false
          end
        end

      end
    end
    return true
  end

  def check_answers token, id_user
    #ritrovo tutti i quesiti della votazione di tipo opzionale
    questions = @poll.questions.where(poll_question_type_id: 3).order("id")

    #ritrovo tutti i voti dati dall'utente corrente per la votazione corrente
    #poll_answers = ::Poll::Answer.by_question(questions.pluck(:id)).by_author(current_user.try(:id)).by_token(token)
    poll_answers = ::Poll::Answer.by_question(questions.pluck(:id)).by_author(id_user).by_token(token)

    questions.each do |question|

        #cerco le risposta date al quesito precondizionale
        #answers = ::Poll::Answer.by_question(@poll.questions.where(id: question.question_optional_id)).by_author(current_user.try(:id)).by_token(token)
        answers = ::Poll::Answer.by_question(@poll.questions.where(id: question.question_optional_id)).by_author(id_user).by_token(token)

        flag = false
        answers.each do |answer|
          if answer.answer == question.poll_question_answer.title
            flag = true
          end
        end
        if !flag
          answers_to_delete = poll_answers.where(question_id: question.id)
          answers_to_delete.each do |answer|
            answer.destroy
          end
        end

    end
  end

  def generate_token
    token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Poll::Answer.exists?(token: random_token)
    end
    token
  end

end



