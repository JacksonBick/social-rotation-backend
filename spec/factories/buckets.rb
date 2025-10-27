FactoryBot.define do
  factory :bucket do
    name { Faker::Lorem.words(number: 3).join(' ').titleize }
    description { Faker::Lorem.paragraph }
    user
    account_id { 1 }
    use_watermark { true }
    post_once_bucket { false }
  end
end





