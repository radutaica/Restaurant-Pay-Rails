class Table < ApplicationRecord
  belongs_to :venue
  has_many :bills, dependent: :destroy
end