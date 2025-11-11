class Bill < ApplicationRecord
    belongs_to :venue
    belongs_to :table
    has_many :bill_line_items, dependent: :destroy

    # Enum pentru status: 0 = open, 1 = partial, 2 = paid, 3 = void/closed
    # Presupunem că status != 0 înseamnă că bill-ul este închis
    enum status: {
      open: 0,
      partial: 1,
      paid: 2,
      closed: 3 # void/closed
    }

    # Callback pentru a șterge sesiunile Redis când bill-ul devine closed
    after_update :delete_sessions_if_closed, if: :saved_change_to_status?

    private

    def delete_sessions_if_closed
      # Ștergem sesiunile dacă status-ul a devenit closed sau paid (bill închis)
      if closed? || paid?
        QpSessionService.delete_sessions_for_bill(id)
        Rails.logger.info "Deleted Redis sessions for bill #{id} (status: #{status})"
      end
    end
  end
