class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV['MAILER_FROM_EMAIL'] || 'noreply@restaurant-pay.com' }
  layout "mailer"
end
