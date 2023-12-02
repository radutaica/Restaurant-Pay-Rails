class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Other Devise modules (e.g., database_authenticatable, registerable, etc.)
  devise :database_authenticatable, :registerable, :recoverable, :validatable
  # JWT authenticatable configuration if needed
  devise :jwt_authenticatable, jwt_revocation_strategy: self 

  def jwt_payload
    super
  end
end
