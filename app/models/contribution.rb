class Contribution < ApplicationRecord
  belongs_to :bill

  VALID_KINDS = %w[full equal_split custom].freeze
  VALID_STATUSES = %w[reserved checkout_created succeeded failed canceled expired].freeze

  validates :requested_amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :allocated_amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tip_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_charge_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :kind, inclusion: { in: VALID_KINDS }, allow_nil: true
  validates :status, inclusion: { in: VALID_STATUSES }, presence: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true

  # Calculate total_charge_cents if not set
  before_validation :calculate_total_charge, if: -> { total_charge_cents.zero? && allocated_amount_cents > 0 }

  private

  def calculate_total_charge
    self.total_charge_cents = allocated_amount_cents + tip_cents
  end
end

