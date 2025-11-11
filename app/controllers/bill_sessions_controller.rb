class BillSessionsController < ApplicationController
  # Endpoint principal pentru scanarea QR code-ului și crearea/obținerea sesiunii de masă
  def create_session
    token = params[:t]
    
    if token.blank?
      render json: { error: 'Token is required' }, status: :bad_request
      return
    end
    
    # Decodăm și validăm tokenul QR
    extracted_data = QrGeneratorService.extract_table_and_venue(token)
    
    if extracted_data.nil?
      render json: { error: 'Invalid QR token' }, status: :unauthorized
      return
    end
    
    begin
      # Găsim venue-ul și masa
      venue = Venue.find(extracted_data[:venue_id])
      table = venue.tables.find(extracted_data[:table_id])
      
      # Verificăm că slug-ul din token corespunde cu cel din baza de date
      if venue.slug != extracted_data[:venue_slug]
        render json: { error: 'Token venue mismatch' }, status: :unauthorized
        return
      end
      
      # Căutăm un Bill deschis pentru masa respectivă
      active_bill = table.bills.open.first
      
      # Dacă nu există, creează unul nou
      if active_bill.nil?
        active_bill = create_new_bill(table, venue)
      end
      
      # Creăm sesiune în Redis
      session_id = QpSessionService.create_session(
        venue_id: venue.id,
        table_id: table.id,
        bill_id: active_bill.id
      )
      
      # Setăm cookie-ul
      cookies[:qp_session] = {
        value: session_id,
        httponly: true,
        secure: Rails.env.production?,
        samesite: :Lax,
        max_age: 900 # 15 minutes
      }
      
      # Returnează informațiile despre sesiunea creată/găsită
      render json: {
        session_token: session_id,
        bill_id: active_bill.id,
        bill: {
          id: active_bill.id,
          status: active_bill.status,
          subtotal_cents: active_bill.subtotal_cents,
          tax_cents: active_bill.tax_cents,
          fees_cents: active_bill.fees_cents,
          tip_cents: active_bill.tip_cents,
          total_cents: active_bill.total_cents,
          currency: active_bill.currency,
          created_at: active_bill.created_at,
          updated_at: active_bill.updated_at
        },
        table: {
          id: table.id,
          name: table.name
        },
        venue: {
          id: venue.id,
          name: venue.name,
          slug: venue.slug,
          address: venue.address,
          currency: venue.currency
        },
        session_info: {
          created_at: Time.current,
          expires_at: 15.minutes.from_now
        }
      }
      
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Table or venue not found' }, status: :not_found
    rescue => e
      Rails.logger.error "Error creating bill session: #{e.message}"
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end
  
  # Endpoint pentru obținerea informațiilor despre sesiunea curentă
  def show_session
    if !load_session_from_redis
      render json: { error: 'Invalid or expired session' }, status: :unauthorized
      return
    end
    
    begin
      bill = Bill.find(@session_data[:bill_id])
      table = Table.find(@session_data[:table_id])
      venue = Venue.find(@session_data[:venue_id])
      
      render json: {
        session_token: get_session_id,
        bill_id: bill.id,
        bill: {
          id: bill.id,
          status: bill.status,
          subtotal_cents: bill.subtotal_cents,
          tax_cents: bill.tax_cents,
          fees_cents: bill.fees_cents,
          tip_cents: bill.tip_cents,
          total_cents: bill.total_cents,
          currency: bill.currency,
          created_at: bill.created_at,
          updated_at: bill.updated_at
        },
        table: {
          id: table.id,
          name: table.name
        },
        venue: {
          id: venue.id,
          name: venue.name,
          slug: venue.slug,
          address: venue.address,
          currency: venue.currency
        },
        session_info: {
          created_at: Time.current,
          expires_at: Time.at(@session_data[:exp])
        }
      }
      
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Session data not found' }, status: :not_found
    end
  end
  
  # Endpoint pentru validarea unui token QR (pentru debugging)
  def validate_qr_token
    token = params[:t]
    
    if token.blank?
      render json: { error: 'Token is required' }, status: :bad_request
      return
    end
    
    extracted_data = QrGeneratorService.extract_table_and_venue(token)
    
    if extracted_data
      render json: {
        valid: true,
        data: extracted_data
      }
    else
      render json: {
        valid: false,
        error: 'Invalid token'
      }, status: :unauthorized
    end
  end
  
  private
  
  def create_new_bill(table, venue)
    Bill.create!(
      table: table,
      venue: venue,
      currency: venue.currency,
      status: :open,
      subtotal_cents: 0,
      tax_cents: 0,
      fees_cents: 0,
      tip_cents: 0,
      total_cents: 0,
      paid_cents: 0,
      remaining_cents: 0
    )
  end
end
