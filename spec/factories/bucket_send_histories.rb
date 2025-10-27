FactoryBot.define do
  factory :bucket_send_history do
    bucket
    bucket_schedule
    bucket_image
    friendly_name { Faker::Lorem.word.titleize }
    text { Faker::Lorem.paragraph }
    twitter_text { Faker::Lorem.sentence(word_count: 10) }
    sent_to { BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER }
    sent_at { 1.hour.ago }
  end
end





