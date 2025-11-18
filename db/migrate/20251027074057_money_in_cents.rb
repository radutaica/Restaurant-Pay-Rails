class MoneyInCents < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :price_cents, :integer, null: false, default: 0
    remove_column :items, :price, :float
    add_column :payments, :amount_cents, :integer, null: false, default: 0
    remove_column :payments, :amount, :float
  end
end
