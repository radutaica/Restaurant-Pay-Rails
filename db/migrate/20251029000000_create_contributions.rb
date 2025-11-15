class CreateContributions < ActiveRecord::Migration[7.0]
  def change
    create_table :contributions do |t|
      t.references :bill, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0  # full | equal_split | custom
      t.integer :requested_amount_cents, null: false, default: 0
      t.integer :allocated_amount_cents, null: false, default: 0
      t.integer :tip_cents, null: false, default: 0
      t.integer :total_charge_cents, null: false, default: 0
      t.string :currency, null: false, default: "ron"
      t.string :stripe_payment_intent_id
      t.integer :status, null: false, default: 0  # reserved | checkout_created | succeeded | failed | canceled | expired
      t.datetime :captured_at
      t.string :guest_session_id
      t.string :payment_method  # checkout | apple_pay | google_pay
      t.timestamps
    end
    
    add_index :contributions, :stripe_payment_intent_id
    add_index :contributions, :bill_id
    add_index :contributions, :status
  end
end

