class ApplicationMailer < ActionMailer::Base
  helper :settings
  default from: "#{Setting['mailer_from_name',User.pon_id]} <#{Setting['mailer_from_address',User.pon_id]}>"
  layout 'mailer'
end
