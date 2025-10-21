class AddTikTokAndYouTubeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :tiktok_access_token, :string
    add_column :users, :tiktok_refresh_token, :string
    add_column :users, :tiktok_user_id, :string
    add_column :users, :tiktok_username, :string
    add_column :users, :youtube_access_token, :string
    add_column :users, :youtube_refresh_token, :string
    add_column :users, :youtube_channel_id, :string
  end
end
