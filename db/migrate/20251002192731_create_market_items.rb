class CreateMarketItems < ActiveRecord::Migration[7.1]
  def change
    create_table :market_items do |t|
      t.references :bucket, null: false, foreign_key: true
      t.references :front_image, null: true, foreign_key: { to_table: :images }
      t.decimal :price
      t.boolean :visible

      t.timestamps
    end
  end
end
