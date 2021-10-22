class Mailer < ApplicationMailer
  before_action :add_logo_attchment
  after_action :prevent_delivery_to_users_without_email

  helper :text_with_links
  helper :mailer
  helper :users

  def comment(comment)
    @comment = comment
    @commentable = comment.commentable
    @email_to = @commentable.author.email
    @legislation_process_name = legislation_process_name(@commentable)

    subject = org_name(@commentable).upcase + " - " + t('mailers.comments_notification.subject')

    with_user(@commentable.author) do
      # subject = t('mailers.comment.subject', commentable: t("activerecord.models.#{@commentable.class.name.underscore}", count: 1).downcase)
      mail(to: @email_to, subject: subject) if @commentable.present? && @commentable.author.present?
    end
  end

  def moderation_action(moderable, html, recipient)
    @html = html
    @moderable = moderable
    @recipient = recipient
    @email_to = recipient.email
    @org_name = Setting['org_name', moderable[:pon_id]]
    subject = @org_name.upcase + " - " + t('mailers.comments_notification.subject')
    mail(to: @email_to, subject: subject)
  end

  def reply(reply)
    @reply = reply
    @commentable = @reply.commentable
    @parent = Comment.find(@reply.parent_id)
    @recipient = @parent.author
    @email_to = @recipient.email

    subject = org_name(@commentable).upcase + " - " + t('mailers.comments_notification.subject')

    with_user(@recipient) do
      mail(to: @email_to, subject: subject) if @commentable.present? && @recipient.present?
    end
  end

  def email_verification(user, recipient, token, document_type, document_number)
    @user = user
    @email_to = recipient
    @token = token
    @document_type = document_type
    @document_number = document_number

    with_user(user) do
      mail(to: @email_to, subject: t('mailers.email_verification.subject'))
    end
  end

  def unfeasible_spending_proposal(spending_proposal)
    @spending_proposal = spending_proposal
    @author = spending_proposal.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.unfeasible_spending_proposal.subject', code: @spending_proposal.code))
    end
  end

  def direct_message_for_receiver(direct_message)
    @direct_message = direct_message
    @receiver = @direct_message.receiver
    @email_to = @receiver.email

    with_user(@receiver) do
      mail(to: @email_to, subject: t('mailers.direct_message_for_receiver.subject'))
    end
  end

  def direct_message_for_sender(direct_message)
    @direct_message = direct_message
    @sender = @direct_message.sender
    @email_to = @sender.email

    with_user(@sender) do
      mail(to: @email_to, subject: t('mailers.direct_message_for_sender.subject'))
    end
  end

  def proposal_notification_digest(user, notifications)
    @notifications = notifications
    @email_to = user.email

    with_user(user) do
      mail(to: @email_to, subject: t('mailers.proposal_notification_digest.title', org_name: Setting['org_name', User.pon_id].to_s))
    end
  end

  def user_invite(email)
    @email_to = email

    I18n.with_locale(I18n.default_locale) do
      mail(to: @email_to, subject: t('mailers.user_invite.subject', org_name: Setting["org_name", User.pon_id]))
    end
  end

  def budget_investment_created(investment)
    @investment = investment
    @email_to = @investment.author.email

    with_user(@investment.author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_created.subject'))
    end
  end

  def moderable_booking_deleted(moderable_booking)
    @moderable_booking = moderable_booking
    @email_to = @moderable_booking.user.email

    with_user(@moderable_booking.user) do
      mail(to: @email_to, subject: "La tua prenotazione è stata cancellata", bcc: ["c.dattilo@almaviva.it"])
    end
  end

  def budget_investment_unfeasible(investment)
    @investment = investment
    @author = investment.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_unfeasible.subject', code: @investment.code))
    end
  end

  def budget_investment_selected(investment)
    @investment = investment
    @author = investment.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_selected.subject', code: @investment.code))
    end
  end

  def budget_investment_unselected(investment)
    @investment = investment
    @author = investment.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_unselected.subject', code: @investment.code))
    end
  end

  def newsletter(newsletter, recipient_email)
    @newsletter = newsletter
    @email_to = recipient_email

    mail(to: @email_to, from: @newsletter.from, subject: @newsletter.subject)
  end

  private

  def add_logo_attchment
    attachments.inline['bari-partecipa-logo.png'] = File.read('app/assets/images/bari-partecipa-logo.png')
  end

  private

  def with_user(user, &block)
    I18n.with_locale(user.locale) do
      yield
    end
  end

  def prevent_delivery_to_users_without_email
    if @email_to.blank?
      mail.perform_deliveries = false
    end
  end

  def org_name(commentable)
    if commentable.class.to_s == 'Legislation::Question'
      leg_process = Legislation::Process.find_by_id(commentable[:legislation_process_id])
      Setting['org_name', leg_process[:pon_id]]
    else
      Setting['org_name', @commentable[:pon_id]]
    end
  end

  def legislation_process_name(commentable)
    if commentable.class.to_s == 'Legislation::Question'
      Legislation::Process.find_by_id(commentable[:legislation_process_id])[:title]
    else
      ''
    end
  end

end
