class CreateClaims < ActiveRecord::Migration[7.0]
  def change
    create_table :claims do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :claim_type, null: false, default: 0  # items/equal/custom
      t.integer :state, null: false, default: 0       # held/paying/paid/expired/canceled
      t.integer :amount_subtotal_cents, null: false, default: 0
      t.integer :tax_cents, null: false, default: 0
      t.integer :fees_cents, null: false, default: 0
      t.integer :tip_cents, null: false, default: 0
      t.integer :amount_total_cents, null: false, default: 0
      t.datetime :expires_at
      t.timestamps
    end

    create_table :claim_units do |t|
      t.references :claim, null: false, foreign_key: true
      t.references :bill_line_item, null: false, foreign_key: true
      t.integer :qty, null: false, default: 0
      t.timestamps
    end
    add_index :claim_units, [:claim_id, :bill_line_item_id], unique: true

    create_table :checkout_sessions do |t|
      t.references :claim, null: false, foreign_key: true
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.integer :status, null: false, default: 0  # pending/succeeded/failed
      t.timestamps
    end
  end
end