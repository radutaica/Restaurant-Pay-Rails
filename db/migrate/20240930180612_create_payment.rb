class CreatePayment < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.float :amount
      t.string :status
      t.string :payment_id
      t.timestamps
    end
  end
end
