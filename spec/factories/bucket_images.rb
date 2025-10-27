FactoryBot.define do
  factory :bucket_image do
    bucket
    image
    friendly_name { Faker::Lorem.word.titleize }
    description { Faker::Lorem.paragraph }
    twitter_description { Faker::Lorem.sentence(word_count: 10) }
    force_send_date { nil }
    repeat { false }
    post_to { 0 }
    use_watermark { true }
  end
end





