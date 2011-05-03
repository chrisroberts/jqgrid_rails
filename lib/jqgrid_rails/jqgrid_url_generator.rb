module JqGridRails
  class UrlGenerator
    if(Rails.version.to_s.split('.').first == '3')
      include Rails.application.routes.url_helpers
    else
      include ActionController::UrlWriter
    end
  end
end
