class Users::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create_payment

    amount = params[:amount].to_i
  
    if amount <= 0
      return render json: { error: 'Invalid amount' }, status: :bad_request
    end
  
    amount_in_cents = amount * 100
    payment = Payment.create(amount: amount, status: 'unpaid')
    payment_intent = Stripe::PaymentIntent.create({
      amount: amount_in_cents,
      currency: 'ron',
      payment_method_types: ['card'],
      confirmation_method: 'automatic',
      capture_method: 'manual',
      metadata: {
        order_id: payment.id,
      },
    })
  
    render json: { client_secret: payment_intent.client_secret }
  rescue Stripe::StripeError => e
    puts e.message
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def pay_bill

    payment = Payment.find(params[:payment_id])
    Stripe::PaymentIntent.capture(payment.payment_intent_id)
    
  end

end