class CreateBucketSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :bucket_schedules do |t|
      t.references :bucket, null: false, foreign_key: true
      t.references :bucket_image, null: true, foreign_key: true
      t.string :schedule
      t.datetime :schedule_time
      t.integer :post_to
      t.integer :type
      t.text :description
      t.text :twitter_description
      t.integer :times_sent
      t.integer :skip_image

      t.timestamps
    end
  end
end
