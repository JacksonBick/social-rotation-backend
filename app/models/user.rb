# User Model
# Represents a user account with authentication, social media connections, and watermark settings
# Links to: buckets, videos, market_items (purchased content)
class User < ApplicationRecord
  # Enable secure password authentication (stores password_digest, provides authenticate method)
  has_secure_password
  
  # ASSOCIATIONS
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

  private

  # Caches Rails environment (development/test/production) to avoid repeated lookups
  # Used in watermark path generation
  def rails_env
    @rails_env ||= Rails.env
  end
end
