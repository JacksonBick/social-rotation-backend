class CreateBucketSendHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :bucket_send_histories do |t|
      t.references :bucket, null: false, foreign_key: true
      t.references :bucket_schedule, null: false, foreign_key: true
      t.references :bucket_image, null: false, foreign_key: true
      t.string :friendly_name
      t.text :text
      t.text :twitter_text
      t.integer :sent_to
      t.datetime :sent_at

      t.timestamps
    end
  end
end
