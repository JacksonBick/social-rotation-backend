# Factory for AccountFeature model
# Creates test account features with default values
FactoryBot.define do
  factory :account_feature do
    association :account
    allow_marketplace { true }
    allow_rss { true }
    allow_integrations { true }
    allow_watermark { true }
    max_users { 50 }
    max_buckets { 100 }
    max_images_per_bucket { 1000 }
    
    # Trait for restrictive features
    trait :restrictive do
      allow_marketplace { false }
      allow_rss { false }
      allow_integrations { false }
      max_users { 1 }
      max_buckets { 5 }
      max_images_per_bucket { 10 }
    end
  end
end
