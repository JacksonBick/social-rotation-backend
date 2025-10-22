class Account < ApplicationRecord
  # Associations
  has_many :users, dependent: :nullify
  has_one :account_feature, dependent: :destroy
  has_many :rss_feeds, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :subdomain, uniqueness: true, allow_nil: true
  
  # Callbacks
  after_create :create_default_features
  
  # Check if this account is a reseller
  def reseller?
    is_reseller
  end
  
  # Get all sub-accounts under this reseller
  def sub_accounts
    users.where.not(is_account_admin: true)
  end
  
  # Get account admins
  def admins
    users.where(is_account_admin: true)
  end
  
  # Check if account can add more users
  def can_add_user?
    return true unless account_feature
    users.active.count < account_feature.max_users
  end
  
  # Check if account can add more buckets
  def can_add_bucket?(user)
    return true unless account_feature
    user.buckets.count < account_feature.max_buckets
  end
  
  private
  
  def create_default_features
    AccountFeature.create!(account: self) unless account_feature
  end
end
