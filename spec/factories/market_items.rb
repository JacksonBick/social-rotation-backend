FactoryBot.define do
  factory :market_item do
    bucket
    front_image { nil }
    price { 9.99 }
    visible { true }
  end
end

