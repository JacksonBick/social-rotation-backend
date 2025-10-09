class CreateUserMarketItems < ActiveRecord::Migration[7.1]
  def change
    create_table :user_market_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :market_item, null: false, foreign_key: true
      t.boolean :visible

      t.timestamps
    end
  end
end
