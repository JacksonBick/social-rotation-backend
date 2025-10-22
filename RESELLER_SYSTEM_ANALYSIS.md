# Reseller System Analysis - Social-Engage

## System Architecture Discovered

### Account Hierarchy

**Based on the original PHP code, here's how the reseller system works:**

```
account_id = 0 → Super Admin / Marketplace Owners
account_id != 0 → Regular Users or Reseller Accounts
```

### Three Types of Users:

1. **Super Admins (account_id = 0)**
   - Create marketplace content
   - Access to all features
   - Manage global marketplace

2. **Reseller Accounts (account_id != 0 + isReseller flag)**
   - Have their own sub-accounts
   - Can create private marketplace for their sub-accounts
   - Manage features for their sub-accounts
   - Account Admin privileges

3. **Regular Users / Sub-Accounts (account_id != 0)**
   - Belong to a reseller (via account_id)
   - Limited to features enabled by their parent account
   - Cannot access marketplace unless parent allows

### Key Relationships:

```
User Model:
- account_id: Links user to their parent Account
- Methods: isAccountAdmin(), account->IsReseller()

Account Model (from ViperCore package):
- Has many users
- has IsReseller() flag
- Manages sub-account permissions
```

### Marketplace Visibility Logic:

From the code:
```php
// Super admins (account_id = 0) see everything
$super_admin_users = User::where('account_id', 0)->get();

// Regular users (account_id != 0) 
$active_users = User::where('account_id', '!=', 0)->where('status', 1)->get();

// Resellers can create private marketplace for their sub-accounts
if ($active_user->isAccountAdmin() && $active_user->account->isReseller())
```

### What We Need to Build:

## 1. Database Schema

### Accounts Table (NEW)
```ruby
create_table :accounts do |t|
  t.string :name, null: false
  t.string :sub_domain
  t.string :top_level_domain
  t.boolean :is_reseller, default: false
  t.boolean :status, default: true
  t.string :support_email
  t.text :terms_conditions
  t.text :privacy_policy
  t.timestamps
end
```

### Users Table (UPDATE)
```ruby
# Add account_id to users
add_column :users, :account_id, :integer, default: 0
# 0 = Super Admin (marketplace owner)
# != 0 = Belongs to a reseller account

# Add role/permission fields
add_column :users, :is_account_admin, :boolean, default: false
add_column :users, :status, :integer, default: 1
```

### AccountFeatures Table (NEW)
```ruby
create_table :account_features do |t|
  t.references :account, foreign_key: true
  t.boolean :allow_marketplace, default: true
  t.boolean :allow_rss, default: true
  t.boolean :allow_integrations, default: true
  t.boolean :allow_watermark, default: true
  t.integer :max_users, default: 1
  t.integer :max_buckets, default: 10
  t.integer :max_images_per_bucket, default: 100
  t.timestamps
end
```

## 2. Models

### Account Model
```ruby
class Account < ApplicationRecord
  has_many :users
  has_one :account_feature
  
  def reseller?
    is_reseller
  end
  
  def super_admin?
    id == 0 # or special flag
  end
end
```

### User Model (UPDATE)
```ruby
class User < ApplicationRecord
  belongs_to :account, optional: true
  
  def super_admin?
    account_id == 0
  end
  
  def account_admin?
    is_account_admin
  end
  
  def reseller?
    account_admin? && account&.reseller?
  end
  
  def can_access_marketplace?
    super_admin? || account&.account_feature&.allow_marketplace
  end
end
```

## 3. Controllers/Authorization

### Key Authorization Logic:
```ruby
# Check if user can create marketplace items
def can_create_marketplace_item?
  current_user.super_admin? || (current_user.account_admin? && current_user.account.reseller?)
end

# Check if user can see a marketplace item
def can_see_marketplace_item?(market_item)
  # Super admins see all
  return true if current_user.super_admin?
  
  # Resellers see their own + public
  # Sub-accounts see what their parent allows
  # Regular users see public only
end

# Check if user can create sub-accounts
def can_create_sub_account?
  current_user.account_admin? && current_user.account.reseller?
end
```

## 4. UI Changes Needed

### Dashboard for Different User Types:

**Super Admin Dashboard:**
- Manage all marketplace items
- See all users/accounts
- System-wide analytics

**Reseller Dashboard:**
- Manage sub-accounts
- Private marketplace for sub-accounts
- Sub-account usage analytics
- Feature permission controls

**Sub-Account Dashboard:**
- Limited to features enabled by parent
- See only allowed marketplace items
- Cannot create sub-accounts

## Next Steps:

1. Create Account model and migration
2. Add account_id to User model
3. Create AccountFeatures model
4. Add authorization/permission checks
5. Build reseller dashboard UI
6. Build sub-account management UI

## Questions for You:

1. Do you want to use the same ViperCore package, or build this from scratch?
2. Should we use a role/permission gem (like Pundit or CanCanCan)?
3. What features should resellers be able to control for sub-accounts?

This is a significant feature - want me to start implementing it?

