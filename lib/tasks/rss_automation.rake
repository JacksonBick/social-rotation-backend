# RSS Automation Rake Tasks
# Run with: rails rss:fetch_all or rails rss:fetch[feed_id]

namespace :rss do
  desc "Fetch all active RSS feeds"
  task fetch_all: :environment do
    puts "Starting RSS feed automation..."
    RssFeedFetchJob.perform_now
    puts "RSS feed automation completed."
  end

  desc "Fetch a specific RSS feed"
  task :fetch, [:feed_id] => :environment do |t, args|
    feed_id = args[:feed_id]
    if feed_id
      puts "Fetching RSS feed ##{feed_id}..."
      RssFeedFetchJob.perform_now(feed_id)
      puts "Feed ##{feed_id} fetch completed."
    else
      puts "Please provide a feed ID: rails rss:fetch[feed_id]"
    end
  end

  desc "Show RSS feed status"
  task status: :environment do
    puts "\n=== RSS Feed Status ==="
    puts "Total feeds: #{RssFeed.count}"
    puts "Active feeds: #{RssFeed.active.count}"
    puts "Healthy feeds: #{RssFeed.active.select(&:healthy?).count}"
    puts "Broken feeds: #{RssFeed.active.select(&:unhealthy?).count}"
    puts "\nFeed Details:"
    RssFeed.active.each do |feed|
      puts "  #{feed.id}. #{feed.name}"
      puts "     Status: #{feed.health_status}"
      puts "     Posts: #{feed.rss_posts.count} (#{feed.unviewed_posts.count} unviewed)"
      puts "     Last fetched: #{feed.last_fetched_at || 'Never'}"
      puts "     Failures: #{feed.fetch_failure_count}"
      puts ""
    end
  end
end

