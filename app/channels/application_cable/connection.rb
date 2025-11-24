module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :session_id

    def connect
      # Get session ID from cookies or params
      self.session_id = get_session_id
      
      if session_id.blank?
        reject_unauthorized_connection
      end
      
      # Verify session is valid
      session_data = QpSessionService.get_session(session_id)
      if session_data.nil?
        reject_unauthorized_connection
      end
    end

    private

    def get_session_id
      # Try cookies first (set by bill_sessions_controller)
      cookies[:qp_session] || 
        # Try connection params
        request.params[:token] ||
        # Try session
        session[:qp_session]
    end
  end
end
