require 'rails_helper'

RSpec.describe Api::V1::RssFeedsController, type: :controller do
  let(:user) { create(:user, super_admin: true) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }

  before do
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'GET #index' do
    let!(:feed1) { create(:rss_feed, user: user) }
    let!(:feed2) { create(:rss_feed, user: user) }

    it 'returns all RSS feeds' do
      get :index
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['rss_feeds'].length).to eq(2)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        url: 'https://feeds.bbci.co.uk/news/rss.xml',
        name: 'BBC News',
        description: 'Latest news from BBC',
        is_active: true
      }
    end

    it 'creates a new RSS feed' do
      expect {
        post :create, params: valid_params
      }.to change(RssFeed, :count).by(1)
      
      expect(response).to have_http_status(:created)
    end

    it 'returns error with invalid params' do
      post :create, params: { url: '' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET #show' do
    let(:feed) { create(:rss_feed, user: user) }

    it 'returns a specific RSS feed' do
      get :show, params: { id: feed.id }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['rss_feed']['id']).to eq(feed.id)
    end
  end

  describe 'PATCH #update' do
    let(:feed) { create(:rss_feed, user: user) }

    it 'updates RSS feed' do
      patch :update, params: { id: feed.id, name: 'Updated Name' }
      expect(response).to have_http_status(:success)
      expect(feed.reload.name).to eq('Updated Name')
    end
  end

  describe 'DELETE #destroy' do
    let!(:feed) { create(:rss_feed, user: user) }

    it 'deletes RSS feed' do
      expect {
        delete :destroy, params: { id: feed.id }
      }.to change(RssFeed, :count).by(-1)
      
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #fetch_posts' do
    let(:feed) { create(:rss_feed, user: user) }

    it 'triggers RSS feed fetching' do
      allow_any_instance_of(RssFetchService).to receive(:fetch_and_parse).and_return({
        success: true,
        message: 'Success',
        posts_found: 10,
        posts_saved: 10
      })

      post :fetch_posts, params: { id: feed.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #fetch_all' do
    it 'triggers fetching all feeds' do
      expect(RssFeedFetchJob).to receive(:perform_later)
      post :fetch_all
      expect(response).to have_http_status(:success)
    end
  end
end

