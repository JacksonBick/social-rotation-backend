class AddHealthStatusToRssFeeds < ActiveRecord::Migration[7.1]
  def change
    add_column :rss_feeds, :last_fetch_error, :string
    add_column :rss_feeds, :fetch_failure_count, :integer
    add_column :rss_feeds, :last_successful_fetch_at, :datetime
  end
end
