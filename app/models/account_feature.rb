class AccountFeature < ApplicationRecord
  belongs_to :account
  
  # Validations
  validates :account, presence: true
  validates :max_users, numericality: { greater_than: 0 }
  validates :max_buckets, numericality: { greater_than: 0 }
  validates :max_images_per_bucket, numericality: { greater_than: 0 }
end
