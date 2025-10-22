class AddAccountFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # account_id already exists, just set default value
    change_column_default :users, :account_id, from: nil, to: 0
    
    add_column :users, :is_account_admin, :boolean, default: false
    add_column :users, :status, :integer, default: 1
    add_column :users, :role, :string, default: 'user'
    
    # Note: We don't add a foreign key constraint because account_id = 0 represents super admins
    # who don't belong to any account
  end
end
