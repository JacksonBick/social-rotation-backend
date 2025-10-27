FactoryBot.define do
  factory :rss_post do
    rss_feed factory: :rss_feed
    title { "Test RSS Post Title" }
    description { "This is a test RSS post description" }
    content { "This is the full content of the RSS post" }
    image_url { "https://example.com/image.jpg" }
    original_url { "https://example.com/article" }
    published_at { 1.day.ago }
    is_viewed { false }
  end
end

