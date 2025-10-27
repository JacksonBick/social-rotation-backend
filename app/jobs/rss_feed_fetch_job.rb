# RSS Feed Fetch Job
# Automatically fetches posts from all active RSS feeds
# Can be run manually or scheduled to run periodically
class RssFeedFetchJob < ApplicationJob
  queue_as :default

  def perform(feed_id = nil)
    if feed_id
      # Fetch a specific feed
      feed = RssFeed.find_by(id: feed_id)
      if feed&.is_active?
        fetch_single_feed(feed)
      end
    else
      # Fetch all active feeds
      active_feeds = RssFeed.active
      Rails.logger.info "RSS Automation: Fetching #{active_feeds.count} active feeds"
      
      active_feeds.find_each do |feed|
        fetch_single_feed(feed)
      end
      
      Rails.logger.info "RSS Automation: Completed fetching all feeds"
    end
  end

  private

  def fetch_single_feed(feed)
    Rails.logger.info "RSS Automation: Fetching feed #{feed.id} - #{feed.name}"
    
    begin
      service = RssFetchService.new(feed)
      result = service.fetch_and_parse
      
      if result[:success]
        feed.record_success!
        Rails.logger.info "RSS Automation: Successfully fetched #{result[:posts_saved]} posts from #{feed.name}"
      else
        feed.record_failure!(result[:error])
        Rails.logger.error "RSS Automation: Failed to fetch #{feed.name}: #{result[:error]}"
      end
    rescue StandardError => e
      feed.record_failure!(e.message)
      Rails.logger.error "RSS Automation: Error fetching #{feed.name}: #{e.message}"
    end
  end
end
