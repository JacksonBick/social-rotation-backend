class Image < ApplicationRecord
  # Associations
  has_many :bucket_images, dependent: :destroy
  has_many :buckets, through: :bucket_images
  has_many :market_items, dependent: :destroy
  
  # Validations
  validates :file_path, presence: true
  
  # Methods from original PHP
  def get_source_url
    # Check if file_path is a DigitalOcean Spaces path (no "uploads/" prefix)
    if file_path.start_with?('production/') || file_path.start_with?('development/') || file_path.start_with?('test/')
      # DigitalOcean Spaces URL - support both naming conventions
      endpoint = ENV['DO_SPACES_ENDPOINT'] || ENV['DIGITAL_OCEAN_SPACES_ENDPOINT'] || 'https://sfo2.digitaloceanspaces.com'
      bucket = ENV['DO_SPACES_BUCKET'] || ENV['DIGITAL_OCEAN_SPACES_NAME']
      "#{endpoint}/#{bucket}/#{file_path}"
    elsif file_path.start_with?('placeholder/')
      # Placeholder image for production without DigitalOcean
      "https://via.placeholder.com/400x300/cccccc/666666?text=Image+Upload+Disabled"
    else
      # Local file URL
      # For development, serve from public folder
      if Rails.env.development? || Rails.env.test?
        "/#{file_path}"
      else
        # For production without DigitalOcean, use a placeholder
        "https://via.placeholder.com/400x300/cccccc/666666?text=Image+Upload+Disabled"
      end
    end
  end
end
