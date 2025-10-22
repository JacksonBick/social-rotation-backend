class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :subdomain
      t.string :top_level_domain
      t.boolean :is_reseller, default: false
      t.boolean :status, default: true
      t.string :support_email
      t.text :terms_conditions
      t.text :privacy_policy

      t.timestamps
    end
    
    add_index :accounts, :subdomain, unique: true
  end
end
