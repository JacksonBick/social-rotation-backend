FactoryBot.define do
  factory :image do
    file_path { "images/#{Faker::Lorem.word}.#{['jpg', 'png', 'gif'].sample}" }
    friendly_name { Faker::Lorem.word.titleize }
  end
end





