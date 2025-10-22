class CreateRssFeeds < ActiveRecord::Migration[7.1]
  def change
    create_table :rss_feeds do |t|
      t.string :url, null: false
      t.string :name, null: false
      t.text :description
      t.integer :account_id, null: false
      t.integer :user_id, null: false
      t.boolean :is_active, default: true
      t.datetime :last_fetched_at

      t.timestamps
    end

    add_index :rss_feeds, :account_id
    add_index :rss_feeds, :user_id
    add_index :rss_feeds, :url
    add_index :rss_feeds, :is_active
  end
end
