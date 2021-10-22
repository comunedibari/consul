module PollsHelper

  def poll_select_options(include_all = nil)
    options = @polls.collect do |poll|
      [poll.name, current_path_with_query_params(poll_id: poll.id)]
    end
    options << all_polls if include_all
    options_for_select(options, request.fullpath)
  end

  def all_polls
    [I18n.t("polls.all"), admin_questions_path]
  end

  def poll_dates(poll)
    if poll.starts_at.blank? || poll.ends_at.blank?
      I18n.t("polls.no_dates")
    else
      I18n.t("polls.dates", open_at: l(poll.starts_at.to_date), closed_at: l(poll.ends_at.to_date))
    end
  end

  def poll_dates_select_options(poll)
    options = []
    (poll.starts_at.to_date..poll.ends_at.to_date).each do |date|
      options << [l(date, format: :long), l(date)]
    end
    options_for_select(options, params[:d])
  end

  def poll_booths_select_options(poll)
    options = []
    poll.booths.each do |booth|
      options << [booth_name_with_location(booth), booth.id]
    end
    options_for_select(options)
  end

  def booth_name_with_location(booth)
    location = booth.location.blank? ? "" : " (#{booth.location})"
    booth.name + location
  end

  def open_answer_content(questionId,answer)
    if current_user.nil?      
      selectedAnswer = Poll::Answer.where(author: User.guest.id,question_id: questionId, answer: answer, token: @token).first
    else
      selectedAnswer = Poll::Answer.where(author: current_user.id,question_id: questionId, answer: answer).first
    end
    if selectedAnswer && selectedAnswer.content
      return selectedAnswer.content
    else
      ""
    end
    
  end

  def poll_voter_token(poll, user)
    Poll::Voter.where(poll: poll, user: user, origin: "web").first&.token || ''
  end

  def voted_before_sign_in(question)
    question.answers.where(author: current_user).any? { |vote| current_user.current_sign_in_at >= vote.updated_at }
  end

  def poll_current_moderable_comments?(poll)
    current_user && poll.moderable_comments_by?(current_user)
  end

  def check_count_votes(question)
    Poll::Answer.where(question_id: question.id ).where(author_id: current_user.id).count < question.num_max_answers
  end

  def chek_optional_qustion_hide(question)
    #controllo se esiste voto
    if @answers_by_question_id[question.question_optional_id].nil?
      false
    else
      if @answers_by_question_id[question.question_optional_id].first.nil?
        false
      else
        #verifico se la risposta concorda
        @answers_by_question_id[question.question_optional_id].first[0] == Poll::Question::Answer.find(question.poll_question_answer_id).title
      end
    end
  end

  def retrieve_opt_question question
    Poll::Question.find(question.question_optional_id)
  end

  def check_cookies_poll poll
    #return true se il cookie è settato
    if poll.flag_cookie
      !cookies["Poll#{poll.id}"].nil?
    else
      false
    end
  end

  def answerable_by_guest
    if current_user.nil? and @poll.access_type == 3
      !check_cookies_poll(@poll)
    else
      false
    end
  end

end
