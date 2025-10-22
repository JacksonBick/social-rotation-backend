# RSS Feed Model
# Represents an RSS feed that can be monitored for new posts
# Only main accounts (resellers) can create RSS feeds for their sub-accounts
class RssFeed < ApplicationRecord
  # ASSOCIATIONS
  belongs_to :account
  belongs_to :user
  has_many :rss_posts, dependent: :destroy
  
  # VALIDATIONS
  validates :url, presence: true, format: { with: URI::regexp(%w[http https]) }
  validates :name, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  
  # SCOPES
  scope :active, -> { where(is_active: true) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  
  # METHODS
  
  # Check if this RSS feed can be managed by the given user
  # Only account admins (resellers) can manage RSS feeds
  def can_be_managed_by?(user)
    return false unless user
    return true if user.super_admin?
    return true if user.account_admin? && user.account_id == account_id
    false
  end
  
  # Get the latest posts from this feed
  def latest_posts(limit = 10)
    rss_posts.order(published_at: :desc).limit(limit)
  end
  
  # Get unprocessed posts
  def unprocessed_posts
    rss_posts.where(is_processed: false).order(published_at: :desc)
  end
  
  # Check if feed needs to be fetched (not fetched in last hour)
  def needs_fetch?
    return true if last_fetched_at.nil?
    last_fetched_at < 1.hour.ago
  end
  
  # Mark feed as fetched
  def mark_as_fetched!
    update!(last_fetched_at: Time.current)
  end
  
  # Get feed status for display
  def status
    return 'inactive' unless is_active?
    return 'never_fetched' if last_fetched_at.nil?
    return 'needs_fetch' if needs_fetch?
    'active'
  end
end
