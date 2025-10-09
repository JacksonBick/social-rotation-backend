class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :name
      t.string :timezone
      t.string :watermark_logo
      t.decimal :watermark_scale
      t.integer :watermark_opacity
      t.integer :watermark_offset_x
      t.integer :watermark_offset_y
      t.integer :account_id
      t.text :fb_user_access_key
      t.string :instagram_business_id
      t.text :twitter_oauth_token
      t.text :twitter_oauth_token_secret
      t.string :twitter_user_id
      t.string :twitter_screen_name
      t.text :linkedin_access_token
      t.datetime :linkedin_access_token_time
      t.string :linkedin_profile_id
      t.text :google_refresh_token
      t.string :location_id
      t.boolean :post_to_instagram
      t.string :twitter_url_oauth_token
      t.string :twitter_url_oauth_token_secret

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
