class Image < ApplicationRecord
  # Associations
  has_many :bucket_images, dependent: :destroy
  has_many :buckets, through: :bucket_images
  has_many :market_items, dependent: :destroy
  
  # Validations
  validates :file_path, presence: true
  
  # Methods from original PHP
  def get_source_url
    "https://se1.sfo2.digitaloceanspaces.com/#{file_path}"
  end
end
