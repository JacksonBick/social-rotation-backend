class CreateRssPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :rss_posts do |t|
      t.integer :rss_feed_id, null: false
      t.string :title, null: false
      t.text :description
      t.text :content
      t.string :image_url
      t.string :original_url
      t.datetime :published_at, null: false
      t.boolean :is_processed, default: false

      t.timestamps
    end

    add_index :rss_posts, :rss_feed_id
    add_index :rss_posts, :published_at
    add_index :rss_posts, :is_processed
    add_index :rss_posts, [:rss_feed_id, :published_at]
  end
end
