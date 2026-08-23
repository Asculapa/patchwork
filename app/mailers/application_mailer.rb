class ApplicationMailer < ActionMailer::Base
  default from: "Patchwork <notifications@patchwork.buzz>"
  layout "mailer"
end
