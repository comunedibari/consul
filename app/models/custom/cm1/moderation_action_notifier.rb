class ModerationActionNotifier

  def initialize(args = {})
    @moderable = args.fetch(:moderable)
    @notification_html = args.fetch(:notification_html)

    begin
      @author  = @moderable.author if @moderable.author.present?
    rescue NoMethodError
      @author  = @moderable.user if @moderable.user.present?
    end

  end

  def process
    send_email
  end

  def send_email
    Mailer.moderation_action(@moderable, @notification_html, @author).deliver_later
  end

end
