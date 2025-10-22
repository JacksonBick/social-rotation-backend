# Factory for Account model
# Creates test accounts with default values for testing reseller functionality
FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    subdomain { Faker::Internet.unique.domain_word }
    top_level_domain { "socialrotation.app" }
    is_reseller { false }
    status { true }
    support_email { Faker::Internet.email }
    terms_conditions { "Test terms and conditions" }
    privacy_policy { "Test privacy policy" }
    
    # Trait for reseller account
    trait :reseller do
      is_reseller { true }
    end
    
    # Trait for inactive account
    trait :inactive do
      status { false }
    end
  end
end
