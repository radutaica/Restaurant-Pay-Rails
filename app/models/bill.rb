class Bill < ApplicationRecord
    belongs_to :venue
    belongs_to :table
    has_many :bill_line_items, dependent: :destroy
    has_many :contributions, dependent: :destroy

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
    
    # Callback pentru a șterge relațiile item-table când bill-ul este complet plătit
    after_update :delete_item_table_relations_if_paid, if: :saved_change_to_remaining_cents?

    private

    def delete_sessions_if_closed
      # Ștergem sesiunile dacă status-ul a devenit closed sau paid (bill închis)
      if closed? || paid?
        QpSessionService.delete_sessions_for_bill(id)
        Rails.logger.info "Deleted Redis sessions for bill #{id} (status: #{status})"
      end
    end
    
    def delete_item_table_relations_if_paid
      # Ștergem relațiile item-table dacă remaining_cents a devenit 0 (bill complet plătit)
      # Verificăm că remaining_cents este 0 și că anterior era > 0 (nu la crearea inițială)
      if remaining_cents == 0 && saved_change_to_remaining_cents.present?
        previous_value, current_value = saved_change_to_remaining_cents
        # Ștergem doar dacă anterior era > 0 și acum este 0
        if previous_value.present? && previous_value > 0 && current_value == 0
          deleted_count = ItemTableRelation.where(table_id: table_id).delete_all
          Rails.logger.info "Deleted #{deleted_count} item-table relations for table #{table_id} (bill #{id} fully paid)"
        end
      end
    end
  end
