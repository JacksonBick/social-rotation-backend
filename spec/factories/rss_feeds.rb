FactoryBot.define do
  factory :rss_feed do
    association :user
    url { "https://feeds.bbci.co.uk/news/rss.xml" }
    name { "Test RSS Feed" }
    description { "A test RSS feed for testing" }
    is_active { true }
    last_fetched_at { nil }
    fetch_failure_count { 0 }
    last_fetch_error { nil }
    last_successful_fetch_at { nil }
    account_id { nil }
  end
end

