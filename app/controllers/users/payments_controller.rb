class Users::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :load_session_from_redis, only: [:create_payment, :pay_bill]

  def create_payment
    # Verifică dacă sesiunea este validă
    unless @session_data
      return render json: { error: 'Invalid or expired session' }, status: :unauthorized
    end

    # Acum poți accesa venue_id, table_id, bill_id din @session_data
    venue_id = @session_data[:venue_id]
    table_id = @session_data[:table_id]
    bill_id = @session_data[:bill_id]

    # Get parameters from request
    requested_amount_cents = params[:requested_amount_cents].to_i
    tip_cents = (params[:tip_cents] || 0).to_i
    kind = params[:kind] || 'custom' # split, custom, full
  
    if requested_amount_cents <= 0
      return render json: { error: 'Invalid requested amount' }, status: :bad_request
    end

    if tip_cents < 0
      return render json: { error: 'Invalid tip amount' }, status: :bad_request
    end

    # Validate kind
    unless Contribution::VALID_KINDS.include?(kind)
      return render json: { error: 'Invalid kind. Must be one of: full, equal_split, custom' }, status: :bad_request
    end

    # Lock bill and calculate remaining amount
    contribution = nil
    payment_intent = nil

    Bill.transaction do
      # Lock the bill with SELECT ... FOR UPDATE
      bill = Bill.lock.find(bill_id)
      
      # Calculate remaining = bill.total_cents - SUM(contributions.succeeded)
      succeeded_total = bill.contributions.where(status: 'succeeded').sum(:allocated_amount_cents)
      remaining = bill.total_cents - succeeded_total

      if remaining <= 0
        raise ActiveRecord::Rollback
      end

      # Calculate allocated = [requested, remaining].min
      allocated = [requested_amount_cents, remaining].min

      # Calculate total charge
      total_charge_cents = allocated + tip_cents

      # Create contribution with status 'reserved'
      contribution = bill.contributions.create!(
        requested_amount_cents: requested_amount_cents,
        allocated_amount_cents: allocated,
        tip_cents: tip_cents,
        total_charge_cents: total_charge_cents,
        currency: bill.currency || 'ron',
        status: 'reserved',
        kind: kind,
        guest_session_id: get_session_id
      )

      # Create PaymentIntent with Stripe
      payment_intent = Stripe::PaymentIntent.create({
        amount: total_charge_cents,
        currency: bill.currency || 'ron',
        payment_method_types: ['card'],
        confirmation_method: 'automatic',
        capture_method: 'automatic',
        metadata: {
          contribution_id: contribution.id,
          bill_id: bill_id,
          venue_id: venue_id,
          table_id: table_id,
        },
      })

      # Store the payment intent ID in the contribution record
      contribution.update!(stripe_payment_intent_id: payment_intent.id)
    end

    # Check if transaction was rolled back due to bill being fully paid
    if contribution.nil? || !contribution.persisted?
      return render json: { error: 'Bill is already fully paid' }, status: :bad_request
    end
  
    render json: { 
      client_secret: payment_intent.client_secret,
      contribution_id: contribution.id,
      allocated_amount_cents: contribution.allocated_amount_cents,
      total_charge_cents: contribution.total_charge_cents
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Bill not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  rescue Stripe::StripeError => e
    # If Stripe fails, the transaction will rollback automatically
    # So contribution won't be persisted, no need to update it
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Error in create_payment: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: 'An error occurred while processing payment' }, status: :internal_server_error
  end

  def pay_bill

    payment = Payment.find(params[:payment_id])
    Stripe::PaymentIntent.capture(payment.payment_id)
    
  end

end