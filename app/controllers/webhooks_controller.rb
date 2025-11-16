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
        contribution.update(status: 'checkout_created')
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
        contribution.update(status: 'failed')
      end
    when 'payment_intent.canceled'
      payment_intent = event.data.object
      contribution = Contribution.find_by(stripe_payment_intent_id: payment_intent.id)
      if contribution
        contribution.update(status: 'canceled')
      end
    when 'payment_intent.processing'
      payment_intent = event.data.object
      # Payment is being processed
    when 'payment_intent.requires_payment_method'
      payment_intent = event.data.object
      contribution = Contribution.find_by(stripe_payment_intent_id: payment_intent.id)
      if contribution
        # Payment intent requires a new payment method, likely expired or invalid
        contribution.update(status: 'expired')
      end
    when 'payment_intent.succeeded'
      payment_intent = event.data.object
      contribution = Contribution.find_by(stripe_payment_intent_id: payment_intent.id)
      if contribution
        # Only process if contribution hasn't already succeeded (prevent double-counting on webhook retries)
        unless contribution.status == 'succeeded'
          # Update contribution status
          contribution.update(status: 'succeeded', captured_at: Time.current)
          
          # Update bill: recalculate paid_cents from succeeded contributions and update remaining_cents
          Bill.transaction do
            # Lock the bill to prevent race conditions
            bill = Bill.lock.find(contribution.bill_id)
            
            # Recalculate paid_cents from sum of all succeeded contributions
            bill.paid_cents = bill.contributions.where(status: 'succeeded').sum(:allocated_amount_cents)
            
            # Recalculate remaining_cents
            bill.remaining_cents = bill.total_cents - bill.paid_cents
            
            # If remaining is 0, mark bill as paid
            if bill.remaining_cents <= 0
              bill.status = :paid
              bill.remaining_cents = 0 # Ensure it's exactly 0
            end
            
            bill.save!
          end
          
          # Send receipt email if email is provided (async via Sidekiq)
          if contribution.email.present?
            begin
              ContributionReceiptMailer.receipt_email(contribution).deliver_later
              Rails.logger.info "Receipt email queued for contribution #{contribution.id} to #{contribution.email}"
            rescue => e
              Rails.logger.error "Failed to queue receipt email for contribution #{contribution.id}: #{e.message}"
              # Don't fail the webhook if email fails
            end
          end
        end
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