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
    # Obținem toate item-urile asociate cu masa
    items = table.items
    
    # Calculăm subtotalul (suma prețurilor tuturor item-urilor)
    subtotal_cents = items.sum(:price_cents)
    
    # Setăm tax_rate_bps și service_fee_bps (poți modifica aceste valori după nevoie)
    # Basis points: 1 bps = 0.01%, deci 1900 bps = 19% (TVA în România)
    tax_rate_bps = 1900 # 19% TVA (poți face configurable din venue sau settings)
    service_fee_bps = 0 # 0% service fee (poți face configurable)
    
    # Calculăm tax-ul: subtotal * (tax_rate_bps / 10000)
    # Exemplu: 10000 cenți * (1900 / 10000) = 10000 * 0.19 = 1900 cenți
    tax_cents = (subtotal_cents * tax_rate_bps / 10000.0).round
    
    # Calculăm service fee-ul: subtotal * (service_fee_bps / 10000)
    fees_cents = (subtotal_cents * service_fee_bps / 10000.0).round
    
    # Tip-ul este 0 la creare (se setează ulterior)
    tip_cents = 0
    
    # Calculăm totalul: subtotal + tax + fees + tip
    total_cents = subtotal_cents + tax_cents + fees_cents + tip_cents
    
    # Creăm bill-ul
    bill = Bill.create!(
      table: table,
      venue: venue,
      currency: venue.currency,
      status: :open,
      tax_rate_bps: tax_rate_bps,
      service_fee_bps: service_fee_bps,
      subtotal_cents: subtotal_cents,
      tax_cents: tax_cents,
      fees_cents: fees_cents,
      tip_cents: tip_cents,
      total_cents: total_cents,
      paid_cents: 0,
      remaining_cents: total_cents
    )
    
    # Creăm bill_line_items pentru fiecare item
    items.each do |item|
      BillLineItem.create!(
        bill: bill,
        item: item,
        name: item.name,
        qty: 1,
        unit_price_cents: item.price_cents,
        subtotal_cents: item.price_cents,
        claimed_qty: 0
      )
    end
    
    bill
  end
end
