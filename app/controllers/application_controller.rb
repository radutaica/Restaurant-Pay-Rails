class ApplicationController < ActionController::Base
    skip_before_action :verify_authenticity_token
    protect_from_forgery with: :null_session
    before_action :configure_permitted_parameters, if: :devise_controller?
    respond_to :json, :html
    include ActionController::MimeResponds

    protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [])
  end
end
