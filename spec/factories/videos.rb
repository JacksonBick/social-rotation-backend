FactoryBot.define do
  factory :video do
    user
    file_path { "videos/#{Faker::Lorem.word}.#{['mp4', 'mov', 'avi'].sample}" }
    friendly_name { Faker::Lorem.word.titleize }
    status { Video::STATUS_UNPROCESSED }
  end
end





