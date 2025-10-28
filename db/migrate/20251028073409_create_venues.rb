class CreateVenues < ActiveRecord::Migration[7.0]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :address
      t.string :currency, default: "ron"
      t.string :stripe_account_id
      t.timestamps
    end
  end
end
