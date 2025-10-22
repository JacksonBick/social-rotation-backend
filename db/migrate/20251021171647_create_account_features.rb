class CreateAccountFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :account_features do |t|
      t.references :account, null: false, foreign_key: true
      t.boolean :allow_marketplace, default: true
      t.boolean :allow_rss, default: true
      t.boolean :allow_integrations, default: true
      t.boolean :allow_watermark, default: true
      t.integer :max_users, default: 50
      t.integer :max_buckets, default: 100
      t.integer :max_images_per_bucket, default: 1000

      t.timestamps
    end
  end
end
