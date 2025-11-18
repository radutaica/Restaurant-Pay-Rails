class Venue < ApplicationRecord
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  
  has_many :tables, dependent: :destroy
  has_many :bills, dependent: :destroy
  has_many :items, dependent: :destroy
end