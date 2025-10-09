class CreateBuckets < ActiveRecord::Migration[7.1]
  def change
    create_table :buckets do |t|
      t.string :name
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.integer :account_id
      t.boolean :use_watermark
      t.boolean :post_once_bucket

      t.timestamps
    end
  end
end
