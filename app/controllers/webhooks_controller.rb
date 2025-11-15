class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET_KEY']
    
    # Check if webhook secret is configured
    unless endpoint_secret.present?
      Rails.logger.error "STRIPE_WEBHOOK_SECRET_KEY is not set in environment variables"
      return render json: { error: 'Webhook secret not configured' }, status: :internal_server_error
    end
    
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    
    event = nil

    begin
        event = Stripe::Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    rescue JSON::ParserError => e
        # Invalid payload
        Rails.logger.error "Invalid JSON payload: #{e.message}"
        return render json: { error: 'Invalid payload' }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        Rails.logger.error "Invalid signature: #{e.message}"
        return render json: { error: 'Invalid signature' }, status: :bad_request
    end

    # Handle the event
    case event.type
    when 'payment_intent.created'
      payment_intent = event.data.object
      if payment_intent.metadata.contribution_id.present?
        contribution = Contribution.find(payment_intent.metadata.contribution_id)
        contribution.update(status: :checkout_created)
      end
    when 'payment_intent.amount_capturable_updated'
      payment_intent = event.data.object
      # Handle if needed for contributions
    when 'checkout.session.completed'
      payment_intent = event.data.object
      # Handle if needed for contributions
    when 'payment_intent.payment_failed'
      payment_intent = event.data.object
      contribution = Contribution.find_by(stripe_payment_intent_id: payment_intent.id)
      if contribution
        contribution.update(status: :failed)
      end
    when 'payment_intent.canceled'
      payment_intent = event.data.object
      contribution = Contribution.find_by(stripe_payment_intent_id: payment_intent.id)
      if contribution
        contribution.update(status: :canceled)
      end
    when 'payment_intent.processing'
      payment_intent = event.data.object
      # Payment is being processed
    when 'payment_intent.succeeded'
      payment_intent = event.data.object
      contribution = Contribution.find_by(stripe_payment_intent_id: payment_intent.id)
      if contribution
        contribution.update(status: :succeeded, captured_at: Time.current)
      end
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end
    
    render json: { received: true }, status: :ok
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