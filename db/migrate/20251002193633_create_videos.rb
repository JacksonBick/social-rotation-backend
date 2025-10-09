class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :file_path
      t.string :friendly_name
      t.integer :status

      t.timestamps
    end
  end
end
