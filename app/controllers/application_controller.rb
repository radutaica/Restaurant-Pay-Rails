class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    respond_to :json, :html
    include ActionController::MimeResponds

    protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [])
  end

  # Citește session_id din cookie sau Authorization header
  # Returnează session_id sau nil
  def get_session_id
    # Încearcă să citească din cookie
    session_id = cookies[:qp_session]
    
    # Dacă nu există în cookie, încearcă din Authorization header
    if session_id.blank?
      auth_header = request.headers['Authorization']
      if auth_header.present? && auth_header.start_with?('Bearer ')
        session_id = auth_header.split(' ').last
      end
    end
    
    # Dacă încă nu există, încearcă din header-ul X-Session-Token (pentru backward compatibility)
    if session_id.blank?
      session_id = request.headers['X-Session-Token'] || request.headers['HTTP_X_SESSION_TOKEN']
    end
    
    # Dacă încă nu există, încearcă din params
    if session_id.blank?
      session_id = params[:session_token]
    end
    
    session_id
  end

  # Citește sesiunea din Redis folosind session_id
  # Setează @session_data dacă sesiunea este validă
  # Returnează true dacă sesiunea este validă, false altfel
  def load_session_from_redis
    session_id = get_session_id
    
    if session_id.blank?
      return false
    end
    
    @session_data = QpSessionService.get_session(session_id)
    
    if @session_data.nil?
      return false
    end
    
    # Verifică dacă sesiunea a expirat (double check, deși Redis ar trebui să o șteargă automat)
    if @session_data[:exp] && Time.current.to_i > @session_data[:exp]
      QpSessionService.delete_session(session_id)
      @session_data = nil
      return false
    end
    
    true
  end
end
