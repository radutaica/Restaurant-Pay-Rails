class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET_KEY']
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return
    end

    case event.type
    when 'payment_intent.created'
      payment_intent = event.data.object
      if payment_intent.metadata && payment_intent.metadata.order_id
        payment = Payment.find(payment_intent.metadata.order_id)
        payment.update(payment_id: payment_intent.id, status: 'unpaid')
      end
    when 'payment_intent.amount_capturable_updated'
      payment_intent = event.data.object
      if payment_intent.metadata && payment_intent.metadata.order_id
        payment = Offer.find(payment_intent.metadata.order_id)
        payment.update(status: "on_hold")
      end
    when 'checkout.session.completed'
      payment_intent = event.data.object
    when 'payment_intent.payment_failed'
      payment_intent = event.data.object
      payment = Payment.find_by(payment_id: payment_intent.id)
      payment&.update(status: 'failed', payment_time: Time.now)
    when 'payment_intent.canceled'
      payment_intent = event.data.object
      payment = Payment.find_by(payment_id: payment_intent.id)
      payment&.update(status: 'cancelled')
    when 'payment_intent.processing'
      payment_intent = event.data.object
    when 'payment_intent.succeeded'
      payment_intent = event.data.object
      payment = Payment.find_by(payment_id: payment_intent.id)
      payment&.update(status: 'paid', payment_time: Time.now)
    else
      puts "Unhandled event type: #{event.type}"
    end

    render json: { message: 'Event processed' }, status: :ok
  end
end
