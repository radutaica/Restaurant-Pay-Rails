class CreateBills < ActiveRecord::Migration[7.0]
  def change
    create_table :bills do |t|
      t.references :table, null: false, foreign_key: true
      t.string  :currency, null: false, default: "ron"
      t.integer :tax_rate_bps, null: false, default: 0   # basis points
      t.integer :service_fee_bps, null: false, default: 0
      t.integer :tip_mode, null: false, default: 0       # enum
      t.integer :status, null: false, default: 0         # open/partial/paid/void
      t.datetime :snapshot_at
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :tax_cents, null: false, default: 0
      t.integer :fees_cents, null: false, default: 0
      t.integer :tip_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.integer :paid_cents, null: false, default: 0
      t.integer :remaining_cents, null: false, default: 0
      t.timestamps
    end

    create_table :bill_line_items do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.string  :name, null: false
      t.integer :qty, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :claimed_qty, null: false, default: 0
      t.integer :subtotal_cents, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :bill_line_items, "claimed_qty <= qty"
  end
end