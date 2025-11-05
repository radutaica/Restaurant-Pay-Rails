class ItemTableRelation < ApplicationRecord
  belongs_to :item
  belongs_to :table
end