class BillsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :load_session_from_redis
  before_action :load_bill_from_session

  # Endpoint pentru actualizarea tip-ului unui bill
  def update_tip
    # Obține tip_cents din params
    tip_cents = params[:tip_cents]&.to_i

    # Validare: tip_cents trebuie să fie >= 0
    if tip_cents.nil? || tip_cents < 0
      render json: { error: 'tip_cents must be a non-negative integer' }, status: :bad_request
      return
    end

    # Verifică că bill-ul este deschis (nu poți modifica tip-ul pentru bill-uri închise)
    unless @bill.open?
      render json: { error: 'Cannot update tip for closed bill' }, status: :unprocessable_entity
      return
    end

    begin
      # Actualizează tip-ul
      @bill.tip_cents = tip_cents

      # Recalculează totalul: subtotal + tax + fees + tip
      @bill.total_cents = @bill.subtotal_cents + @bill.tax_cents + @bill.fees_cents + @bill.tip_cents

      # Recalculează remaining_cents: total - paid
      @bill.remaining_cents = @bill.total_cents - @bill.paid_cents

      # Salvează bill-ul
      @bill.save!

      # Returnează bill-ul actualizat
      render json: {
        bill: {
          id: @bill.id,
          status: @bill.status,
          subtotal_cents: @bill.subtotal_cents,
          tax_cents: @bill.tax_cents,
          fees_cents: @bill.fees_cents,
          tip_cents: @bill.tip_cents,
          total_cents: @bill.total_cents,
          paid_cents: @bill.paid_cents,
          remaining_cents: @bill.remaining_cents,
          currency: @bill.currency,
          updated_at: @bill.updated_at
        }
      }

    rescue => e
      Rails.logger.error "Error updating bill tip: #{e.message}"
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  # Endpoint pentru obținerea informațiilor despre bill
  def show
    render json: {
      bill: {
        id: @bill.id,
        status: @bill.status,
        subtotal_cents: @bill.subtotal_cents,
        tax_cents: @bill.tax_cents,
        fees_cents: @bill.fees_cents,
        tip_cents: @bill.tip_cents,
        total_cents: @bill.total_cents,
        paid_cents: @bill.paid_cents,
        remaining_cents: @bill.remaining_cents,
        currency: @bill.currency,
        created_at: @bill.created_at,
        updated_at: @bill.updated_at
      }
    }
  end

  private

  def load_bill_from_session
    unless @session_data
      render json: { error: 'Invalid or expired session' }, status: :unauthorized
      return
    end

    @bill = Bill.find(@session_data[:bill_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Bill not found' }, status: :not_found
  end
end

