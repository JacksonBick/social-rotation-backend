class AccountFeature < ApplicationRecord
  belongs_to :account
  
  # Validations
  validates :account, presence: true
  validates :max_users, numericality: { greater_than: 0 }
  validates :max_buckets, numericality: { greater_than: 0 }
  validates :max_images_per_bucket, numericality: { greater_than: 0 }
  
  # Default values for new account features
  after_initialize :set_defaults, if: :new_record?
  
  private
  
  def set_defaults
    self.allow_marketplace ||= false
    self.allow_rss ||= true  # Enable RSS by default for all accounts
    self.max_users ||= 50
    self.max_buckets ||= 100
    self.max_images_per_bucket ||= 1000
  end
end
