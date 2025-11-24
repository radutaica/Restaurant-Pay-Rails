class PaymentUpdatesChannel < ApplicationCable::Channel
  def subscribed
    # Get bill_id from params (passed from client)
    bill_id = params[:bill_id]
    
    if bill_id.blank?
      Rails.logger.warn "ActionCable: Rejected subscription - no bill_id"
      reject
      return
    end
    
    # Verify session is valid (session_id is set in Connection#connect)
    session_id = connection.session_id
    unless session_id.present?
      Rails.logger.warn "ActionCable: Rejected subscription - no session_id"
      reject
      return
    end
    
    session_data = QpSessionService.get_session(session_id)
    unless session_data && session_data[:bill_id].to_s == bill_id.to_s
      Rails.logger.warn "ActionCable: Rejected subscription - invalid session or bill_id mismatch"
      reject
      return
    end
    
    # Subscribe to the stream for this specific bill
    stream_from "payment_updates:#{bill_id}"
    
    Rails.logger.info "ActionCable: Client subscribed to payment_updates:#{bill_id} (session: #{session_id[0..8]}...)"
    
    # Send initial connection confirmation
    transmit({
      type: 'connected',
      bill_id: bill_id,
      timestamp: Time.current.iso8601
    })
  end

  def unsubscribed
    Rails.logger.info "ActionCable: Client unsubscribed from payment_updates:#{params[:bill_id]}"
  end
end

