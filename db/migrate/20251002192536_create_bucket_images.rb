class CreateBucketImages < ActiveRecord::Migration[7.1]
  def change
    create_table :bucket_images do |t|
      t.references :bucket, null: false, foreign_key: true
      t.references :image, null: false, foreign_key: true
      t.string :friendly_name
      t.text :description
      t.text :twitter_description
      t.datetime :force_send_date
      t.boolean :repeat
      t.integer :post_to
      t.boolean :use_watermark

      t.timestamps
    end
  end
end
