class PaymentBroadcastService
  class << self
    # Broadcast a payment update for a specific bill using ActionCable
    # This will be received by all clients subscribed to that bill's channel
    def broadcast_payment_update(bill_id:, contribution: nil, bill: nil)
      data = {
        type: 'payment_completed',
        bill_id: bill_id,
        timestamp: Time.current.iso8601
      }
      
      # Include contribution details if provided
      if contribution
        data[:contribution] = {
          id: contribution.id,
          allocated_amount_cents: contribution.allocated_amount_cents,
          tip_cents: contribution.tip_cents,
          total_charge_cents: contribution.total_charge_cents,
          status: contribution.status,
          currency: contribution.currency
        }
      end
      
      # Include bill details if provided
      if bill
        data[:bill] = {
          id: bill.id,
          total_cents: bill.total_cents,
          paid_cents: bill.paid_cents,
          remaining_cents: bill.remaining_cents,
          status: bill.status
        }
      end
      
      # Broadcast using ActionCable - this handles all the Redis pub/sub automatically
      ActionCable.server.broadcast("payment_updates:#{bill_id}", data)
      Rails.logger.info "ActionCable: Broadcasted payment update for bill #{bill_id}"
    end
  end
end

