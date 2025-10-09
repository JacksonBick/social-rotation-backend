class Video < ApplicationRecord
  # Constants from original PHP
  STATUS_UNPROCESSED = 0
  STATUS_PROCESSING = 1
  STATUS_PROCESSED = 2
  
  # Associations
  belongs_to :user
  
  # Validations
  validates :file_path, presence: true
  validates :status, presence: true, inclusion: { in: [STATUS_UNPROCESSED, STATUS_PROCESSING, STATUS_PROCESSED] }
  
  # Methods from original PHP
  def get_source_url
    "https://se1.sfo2.digitaloceanspaces.com/#{file_path}"
  end
end
