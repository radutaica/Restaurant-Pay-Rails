class Contribution < ApplicationRecord
  belongs_to :bill

  enum kind: {
    full: 0,
    equal_split: 1,
    custom: 2
  }

  enum status: {
    reserved: 0,
    checkout_created: 1,
    succeeded: 2,
    failed: 3,
    canceled: 4,
    expired: 5
  }

  validates :requested_amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :allocated_amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tip_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_charge_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :stripe_checkout_session_id, uniqueness: true, allow_nil: true

  # Calculate total_charge_cents if not set
  before_validation :calculate_total_charge, if: -> { total_charge_cents.zero? && allocated_amount_cents > 0 }

  private

  def calculate_total_charge
    self.total_charge_cents = allocated_amount_cents + tip_cents
  end
end

