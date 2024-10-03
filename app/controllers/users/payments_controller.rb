class Users::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create_payment
    amount = params[:amount].to_i * 100

    payment_intent = Stripe::PaymentIntent.create({
      amount: amount,
      currency: 'usd',
    })

    render json: { client_secret: payment_intent.client_secret }
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end