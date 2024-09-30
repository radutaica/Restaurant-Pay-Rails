class CreateItemTableRelation < ActiveRecord::Migration[7.0]
  def change
    create_table :item_table_relations do |t|
      t.bigint :item_id
      t.bigint :table_id
      t.timestamps
    end
  end
end
