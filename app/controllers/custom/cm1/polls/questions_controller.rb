class Polls::QuestionsController < ApplicationController


  load_and_authorize_resource :poll
  load_and_authorize_resource :question, class: 'Poll::Question'
  respond_to :html, :js
  before_action :load_data, only: :answer

  has_orders %w{most_voted newest oldest}, only: :show

  def get_user_by_token(token)
    voter = Poll::Voter.find_by token: token

    if voter.nil?
      return User.guest
    end

    User.find(voter.user_id)
  end

  def answer

    if current_user.nil?
      tmp_user = get_user_by_token(params[:token])
    else
      tmp_user = current_user
    end

    @poll = Poll.find(@question.poll_id)
    @questions = @poll.questions.for_render.sort_for_list
    @poll_questions_answers = Poll::Question::Answer.where(question: @poll.questions).where.not(description: "").order(:given_order)

    @answers_by_question_id = {}
    poll_answers = ::Poll::Answer.by_question(@poll.question_ids).by_author(tmp_user.try(:id)).by_token(@token)

    poll_answers.each do |answer|
      unless @answers_by_question_id[answer.question_id]
        @answers_by_question_id[answer.question_id] = Hash.new
      end
      @answers_by_question_id[answer.question_id][answer.answer] = answer.answer
    end

    if Poll::Answer.where(author: tmp_user, question_id: @question.id, answer: params[:answer], token: @token).any? and params[:answer] != 'Altro'
      Poll::Answer.where(author: tmp_user, question_id: @question.id, answer: params[:answer], token: @token).delete_all
      @answers_by_question_id[@question.id].delete(params[:answer])

    else
      flag = true
      if @poll_answers.count >= @question.num_max_answers && @question.num_max_answers > 1
        if params[:answer] == 'Altro'
          if @poll_answers.where(answer: "Altro").count < 1
            #render :new
            flag = false
          else
            flag = true
          end
        else
          #render :new
          flag = false
        end
      end
      if !flag
        render :new
      else
        if @poll_answers.count == 1 and @question.num_max_answers == 1
          @poll_answers.first.destroy
        end

        if params[:answer] == 'Altro' && @poll_answers.where(answer: "Altro").count > 0
          @poll_answers.where(answer: "Altro").first.destroy
        end

        if params[:answer] != 'Altro' || params[:content] != ""
          answer = @question.answers.new(author: tmp_user)
          token = params[:token]
          answer.answer = params[:answer]
          answer.content = params[:content]
          answer.token = token
          answer.touch if answer.persisted?
          answer.save!
          answer.record_voter_participation(token)
          logger.info "---Question - #{@question.id} - answers count #{@question.question_answers.where(question_id: @question).count}"
          @question.question_group.question_answers.where(question_id: @question).each do |question_answer|
            question_answer.set_most_voted_by_question @question
          end

          if @question.num_max_answers == 1 || !@answers_by_question_id || !@answers_by_question_id[@question.id]
            @answers_by_question_id[@question.id] = Hash.new
          end
          @answers_by_question_id[@question.id][answer.answer] = answer.answer
        else
          if @question.num_max_answers == 1
            @answers_by_question_id[@question.id] = Hash.new
          end
        end
      end
    end
  end


  def load_data
    if current_user.nil?
      tmp_user = User.guest
    else
      tmp_user = current_user
    end

    @token = params[:token]
    @answers_by_question_id = {}
    @poll_answers = ::Poll::Answer.by_question(@question.id).by_author(tmp_user.try(:id)).by_token(@token)

    @poll_answers.each do |answer|
      unless @answers_by_question_id[answer.question_id]
        @answers_by_question_id[answer.question_id] = Hash.new
      end
      @answers_by_question_id[answer.question_id][answer.answer] = answer.answer
    end
  end

end
