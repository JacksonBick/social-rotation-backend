# User Model
# Represents a user account with authentication, social media connections, and watermark settings
# Links to: buckets, videos, market_items (purchased content)
class User < ApplicationRecord
  # Enable secure password authentication (stores password_digest, provides authenticate method)
  has_secure_password
  
  # ASSOCIATIONS
  # User belongs to an Account (for reseller/sub-account system)
  # account_id = 0 means super admin, > 0 means belongs to a reseller account
  belongs_to :account, optional: true
  
  # User owns multiple buckets (content collections) - destroy buckets when user is deleted
  has_many :buckets, dependent: :destroy
  # User has access to bucket_schedules through their buckets
  has_many :bucket_schedules, through: :buckets
  # User owns multiple videos - destroy videos when user is deleted
  has_many :videos, dependent: :destroy
  # User has purchased market items - destroy purchase records when user is deleted
  has_many :user_market_items, dependent: :destroy
  # User can access purchased market items through user_market_items
  has_many :market_items, through: :user_market_items
  # User can create RSS feeds (only account admins)
  has_many :rss_feeds, dependent: :destroy
  
  # VALIDATIONS
  # Email must exist, be unique, and match valid email format
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # Name must be present
  validates :name, presence: true
  
  # WATERMARK METHODS - Generate paths for user's watermark logo
  
  # Returns URL path for watermark preview image
  # Used by frontend to show watermark preview
  def get_watermark_preview
    '/user/standard_preview'
  end
  
  # Returns relative path for Digital Ocean storage
  # Format: "environment/user_id/watermarks/logo_filename"
  # Example: "production/123/watermarks/logo.png"
  def get_relative_digital_ocean_watermark_path
    "#{rails_env}/#{id}/watermarks/#{watermark_logo}"
  end
  
  # Returns full CDN URL for watermark logo on Digital Ocean Spaces
  # Returns empty string if no watermark logo exists
  # Example: "https://se1.sfo2.digitaloceanspaces.com/production/123/watermarks/logo.png"
  def get_digital_ocean_watermark_path
    watermark_logo ? "https://se1.sfo2.digitaloceanspaces.com/#{rails_env}/#{id}/watermarks/#{watermark_logo}" : ''
  end
  
  # Returns local storage path for watermark logo
  # Used for serving watermark from local storage
  # Returns empty string if no watermark logo exists
  def get_watermark_logo
    watermark_logo ? "/storage/#{rails_env}/#{id}/watermarks/#{watermark_logo}" : ''
  end
  
  # Returns absolute filesystem path to user's watermark directory
  # Used for file operations (saving/reading watermarks)
  # Returns empty string if no watermark logo exists
  def get_absolute_watermark_logo_directory
    watermark_logo ? Rails.root.join("public/storage/#{rails_env}/#{id}").to_s : ''
  end
  
  # Returns absolute filesystem path to scaled watermark directory
  # Scaled watermarks are pre-processed versions for different image sizes
  # Returns empty string if no watermark logo exists
  def get_absolute_watermark_scaled_logo_directory
    watermark_logo ? Rails.root.join("public/storage/#{rails_env}/#{id}/watermarks_scaled").to_s : ''
  end
  
  # Returns absolute filesystem path to specific watermark logo file
  # Used for direct file access (reading/processing watermark)
  # Returns empty string if no watermark logo exists
  def get_absolute_watermark_logo_path
    watermark_logo ? Rails.root.join("public/storage/#{rails_env}/#{id}/watermarks/#{watermark_logo}").to_s : ''
  end
  
  # ACCOUNT/RESELLER METHODS
  
  # Check if user is a super admin (account_id = 0)
  # Super admins have full access to everything including marketplace creation
  def super_admin?
    account_id == 0
  end
  
  # Check if user is an account admin (can manage sub-accounts)
  def account_admin?
    is_account_admin
  end
  
  # Check if user is a reseller (account admin + reseller account)
  # Resellers can create sub-accounts and private marketplaces
  def reseller?
    account_admin? && account&.reseller? || false
  end
  
  # Check if user can access marketplace
  def can_access_marketplace?
    super_admin? || account&.account_feature&.allow_marketplace
  end
  
  # Check if user can create marketplace items
  def can_create_marketplace_item?
    super_admin? || reseller?
  end
  
  # Check if user can create sub-accounts
  def can_create_sub_account?
    reseller?
  end
  
  # Check if user can manage RSS feeds
  def can_manage_rss_feeds?
    super_admin? || reseller?
  end
  
  # Check if user can access RSS feeds
  def can_access_rss_feeds?
    super_admin? || account&.account_feature&.allow_rss
  end
  
  # Get all users in the same account (for account admins)
  def account_users
    return User.none unless account_id && account_id > 0
    User.where(account_id: account_id)
  end
  
  # Scope for active users
  scope :active, -> { where(status: 1) }

  private

  # Caches Rails environment (development/test/production) to avoid repeated lookups
  # Used in watermark path generation
  def rails_env
    @rails_env ||= Rails.env
  end
end
