class RenameIsProcessedToIsViewedInRssPosts < ActiveRecord::Migration[7.1]
  def change
    rename_column :rss_posts, :is_processed, :is_viewed
  end
end
