FactoryBot.define do
  factory :bucket_schedule do
    bucket
    bucket_image
    schedule { "0 9 * * 1-5" } # 9 AM weekdays
    schedule_time { 1.day.from_now }
    post_to { BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER }
    schedule_type { BucketSchedule::SCHEDULE_TYPE_ROTATION }
    description { Faker::Lorem.paragraph }
    twitter_description { Faker::Lorem.sentence(word_count: 10) }
    times_sent { 0 }
    skip_image { 0 }
  end
end
