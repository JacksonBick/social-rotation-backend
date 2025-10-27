require 'rails_helper'

RSpec.describe RssPost, type: :model do
  describe 'associations' do
    it { should belong_to(:rss_feed) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:rss_feed_id) }
  end

  describe 'scopes' do
    let!(:viewed_post) { create(:rss_post, is_viewed: true) }
    let!(:unviewed_post) { create(:rss_post, is_viewed: false) }

    it 'returns viewed posts' do
      expect(RssPost.viewed).to include(viewed_post)
      expect(RssPost.viewed).not_to include(unviewed_post)
    end

    it 'returns unviewed posts' do
      expect(RssPost.unviewed).to include(unviewed_post)
      expect(RssPost.unviewed).not_to include(viewed_post)
    end

    it 'returns recent posts' do
      old_post = create(:rss_post, published_at: 2.days.ago)
      recent_post = create(:rss_post, published_at: 1.hour.ago)
      
      expect(RssPost.recent).to include(recent_post)
      expect(RssPost.recent).not_to include(old_post)
    end
  end

  describe '#has_image?' do
    it 'returns true when image_url is present' do
      post = create(:rss_post, image_url: "https://example.com/image.jpg")
      expect(post.has_image?).to be true
    end

    it 'returns false when image_url is nil' do
      post = create(:rss_post, image_url: nil)
      expect(post.has_image?).to be false
    end
  end

  describe '#mark_as_viewed!' do
    it 'marks post as viewed' do
      post = create(:rss_post, is_viewed: false)
      post.mark_as_viewed!
      
      expect(post.is_viewed).to be true
    end
  end

  describe '#short_title' do
    it 'returns full title when less than max length' do
      post = create(:rss_post, title: "Short title")
      expect(post.short_title(50)).to eq("Short title")
    end

    it 'truncates long titles' do
      post = create(:rss_post, title: "This is a very long title that needs to be truncated")
      expect(post.short_title(20)).to eq("This is a very lo...")
    end
  end

  describe '#short_description' do
    it 'returns full description when less than max length' do
      post = create(:rss_post, description: "Short desc")
      expect(post.short_description(50)).to eq("Short desc")
    end

    it 'truncates long descriptions' do
      post = create(:rss_post, description: "This is a very long description that needs to be truncated")
      expect(post.short_description(20)).to eq("This is a very lo...")
    end
  end
end

