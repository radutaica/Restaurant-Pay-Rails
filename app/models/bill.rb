class Bill < ApplicationRecord
    belongs_to :venue
    belongs_to :table
  end
