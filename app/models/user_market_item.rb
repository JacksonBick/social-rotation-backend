class UserMarketItem < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :market_item
  
  # Validations
  validates :visible, inclusion: { in: [true, false] }
end
