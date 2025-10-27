class MakeAccountIdNullableInRssFeeds < ActiveRecord::Migration[7.1]
  def change
    change_column_null :rss_feeds, :account_id, true
  end
end
