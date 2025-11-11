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

    amount = params[:amount].to_i
  
    if amount <= 0
      return render json: { error: 'Invalid amount' }, status: :bad_request
    end
  
    # Convert amount from base currency (RON) to cents
    # Frontend sends amount in base currency, Stripe requires cents
    amount_in_cents = amount
    payment = Payment.create(amount_cents: amount_in_cents, status: 'unpaid')
    payment_intent = Stripe::PaymentIntent.create({
      amount: amount_in_cents,
      currency: 'ron',
      payment_method_types: ['card'],
      confirmation_method: 'automatic',
      capture_method: 'automatic',
      metadata: {
        order_id: payment.id,
        venue_id: venue_id,
        table_id: table_id,
        bill_id: bill_id,
      },
    })
  
    # Store the payment intent ID in the payment record
    payment.update(payment_id: payment_intent.id)
  
    render json: { client_secret: payment_intent.client_secret }
  rescue Stripe::StripeError => e
    puts e.message
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def pay_bill

    payment = Payment.find(params[:payment_id])
    Stripe::PaymentIntent.capture(payment.payment_id)
    
  end

end