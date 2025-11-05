class Item < ApplicationRecord
  belongs_to :venue
  has_many :item_table_relations
  has_many :tables, through: :item_table_relations
end