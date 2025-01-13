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
        # Invalid payload
        puts e
        return
    rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        puts e
        return
    end

    # Handle the event
    case event.type
    when 'payment_intent.created'
      payment_intent = event.data.object
      payment = Payment.find(payment_intent.metadata.order_id)
      payment.update(payment_id: payment_intent.id, status: 'unpaid')
    when 'payment_intent.amount_capturable_updated'
      payment_intent = event.data.object
      payment = Offer.find(payment_intent.metadata.order_id)
      payment.update(status: "on_hold")
    when 'checkout.session.completed'
      payment_intent = event.data.object
    when 'payment_intent.payment_failed'
      payment_intent = event.data.object
      payment = Payment.find_by(payment_id: payment_intent.id)
      payment.update(status: 'failed', payment_time: Time.now)
    when 'payment_intent.canceled'
      payment_intent = event.data.object
      payment = Payment.find_by(payment_id: payment_intent.id)

      if payment
        payment.update(status: 'cancelled')
      else
        return
      end
    when 'payment_intent.processing'
      payment_intent = event.data.object
    when 'payment_intent.succeeded'
      payment_intent = event.data.object
      payment = Payment.find_by(payment_id: payment_intent.id)
      payment.update(status: 'paid',  payment_time: Time.now)
    else
      puts "Unhandled event type: #{event.type}"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_webhook
      @webhook = Webhook.find(params[:id])
    end

    def set_account_status(account_id, status)
      User.find_by(account_id: account_id).change_status(status) if status == "active" || status == "pending"
    end

    # Only allow a list of trusted parameters through.
    def webhook_params
      params.fetch(:webhook, {})
    end
end