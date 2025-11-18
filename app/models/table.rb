class Table < ApplicationRecord
  belongs_to :venue
  has_many :bills, dependent: :destroy
  has_many :item_table_relations
  has_many :items, through: :item_table_relations
end