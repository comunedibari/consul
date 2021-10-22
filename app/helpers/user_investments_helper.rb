module UserInvestmentsHelper

  def my_accepted_investments(crowdfunding)
    total_investments = UserInvestment.all.where(crowdfunding_id: crowdfunding.id).where(user_id: current_user.id).where(status: "accepted").order(created_at: :desc)
    investment = 0
    total_investments.each do |i|
      investment = investment + i.value_investements
    end
    investment
  end

  def current_user_investments_by(crowdfunding)
    @total_investments = UserInvestment.all.where(crowdfunding_id: crowdfunding.id).where(user_id: current_user.id).order(created_at: :desc)
  end

  def crowdfunding_successful_investments(crowdfunding)
    @investments = UserInvestment.all.where(crowdfunding_id: @crowdfunding.id).where(status: UserInvestment.statuses[:accepted]).order(created_at: :desc)
  end

  def date_until_now(user_investment)
    time_ago_in_words(user_investment.created_at, include_seconds: true)
  end

  def number_investors(crowdfunding)
    @number_investors = UserInvestment.select(:user_id).where(crowdfunding_id: @crowdfunding.id).uniq.count #.where("user_id != ?", current_user ).count + 1
  end

  def view_status(user_investment)
    if user_investment.accepted?
      "accreditato".upcase
    elsif user_investment.rejected?
      "annullato".upcase
    else
      "in verifica".upcase
    end
  end

  def get_status_badge_class(user_investment)
    if user_investment.accepted?
      "success"
    elsif user_investment.rejected?
      "danger"
    else
      "secondary"
    end
  end

  ##
  # Stabilisce se il campo del form di inserimento dello UserInvestment sarà disabilitato o meno,
  # a seconda di questa logica:
  # - Utente guest: sempre tutto abilitato
  # - Utente social: abilitato solo i campi finanziatore (:investor) e codice fiscale
  # - Utente SPID: tutto disabilitato
  def is_field_disabled(user, field)
    social_disabled_fields = []
    spid_disabled_fields = [:email, :fiscal_code]

    # Se il current user non c'è, significa che l'utente è guest e restituiamo sempre false
    if user == nil
      false
      return
    end

    if user.is_social?
      if social_disabled_fields.include? field
        return true
      else
        return false
      end
    end

    if user.is_spid?
      if spid_disabled_fields.include? field
        return true
      else
        return false
      end
    end
  end

  def get_value_from_account(user, field)
    if !user.nil?
      instance_eval 'user.' + field
    else
      ''
    end
  end
end
