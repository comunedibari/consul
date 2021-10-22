module ScoreCalculator

  EPOC           = Time.new(2015, 6, 15).in_time_zone
  COMMENT_WEIGHT = 1.0 / 5 # 1 positive vote / x comments
  DAY_WEIGHT = 10 # day elapsed for crowdfundings
  TIME_UNIT      = 24.hours.to_f

  def self.hot_score(date, votes_total, votes_up, comments_count)
    total   = (votes_total + COMMENT_WEIGHT * comments_count).to_f
    ups     = (votes_up    + COMMENT_WEIGHT * comments_count).to_f
    downs   = total - ups
    score   = ups - downs
    offset  = Math.log([score.abs, 1].max, 10) * (ups / [total, 1].max)
    sign    = score <=> 0
    seconds = ((date || Time.current) - EPOC).to_f

    (((offset * sign) + (seconds / TIME_UNIT)) * 10000000).round
  end

  def self.confidence_score(votes_total, votes_up)
    return 1 unless votes_total > 0

    votes_total = votes_total.to_f
    votes_up    = votes_up.to_f
    votes_down  = votes_total - votes_up
    score       = votes_up - votes_down

    score * (votes_up / votes_total) * 100
  end

  def self.confidence_score_crowdfunding(count_investors, total_investiment, price_goal, min_price)
    return 1 unless count_investors.to_i > 0
    count_investors * 100
  end

  def self.hot_score_crowdfunding(start_date, end_date, total_investiment, count_investors, price_goal, min_price, comments_count)
    seconds = ((start_date || Time.current) - EPOC).to_f
    total_comments   = (COMMENT_WEIGHT * comments_count).to_f
    days_missing = (end_date.to_date - Time.current.beginning_of_day.to_date).to_f
    days_total = (end_date.to_date - start_date.to_date).to_f

    if total_investiment != nil
      score = (total_investiment/price_goal * 100)
    else
      score = 0
    end

    if score == 0
      score = score + (days_missing/days_total).to_f * DAY_WEIGHT
      score = score * 10000
      score = score + total_comments
    elsif score < 100
      score = score + (days_missing/days_total) * DAY_WEIGHT
      score = score * 10000
      score = score + total_comments
    elsif score >= 100
      score = score  
    end

    score
    
  end

end
