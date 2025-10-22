# RSS Feeds Controller
# Handles RSS feed management for reseller accounts
# Only account admins (resellers) can create/manage RSS feeds
class Api::V1::RssFeedsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_rss_access!
  before_action :set_rss_feed, only: [:show, :update, :destroy, :fetch_posts, :posts]

  # GET /api/v1/rss_feeds
  def index
    if current_user.super_admin?
      @rss_feeds = RssFeed.includes(:account, :user).order(:created_at)
    else
      @rss_feeds = current_user.account.rss_feeds.includes(:user).order(:created_at)
    end

    render json: {
      rss_feeds: @rss_feeds.map { |feed| rss_feed_json(feed) }
    }
  end

  # GET /api/v1/rss_feeds/:id
  def show
    render json: {
      rss_feed: rss_feed_json(@rss_feed),
      recent_posts: @rss_feed.latest_posts(5).map { |post| rss_post_json(post) }
    }
  end

  # POST /api/v1/rss_feeds
  def create
    @rss_feed = current_user.rss_feeds.build(rss_feed_params)
    @rss_feed.account_id = current_user.account_id

    if @rss_feed.save
      render json: {
        rss_feed: rss_feed_json(@rss_feed),
        message: 'RSS feed created successfully'
      }, status: :created
    else
      render json: {
        errors: @rss_feed.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/rss_feeds/:id
  def update
    if @rss_feed.update(rss_feed_params)
      render json: {
        rss_feed: rss_feed_json(@rss_feed),
        message: 'RSS feed updated successfully'
      }
    else
      render json: {
        errors: @rss_feed.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/rss_feeds/:id
  def destroy
    @rss_feed.destroy
    render json: { message: 'RSS feed deleted successfully' }
  end

  # POST /api/v1/rss_feeds/:id/fetch_posts
  def fetch_posts
    # This would trigger RSS fetching in a background job
    # For now, we'll just mark it as fetched
    @rss_feed.mark_as_fetched!
    
    render json: {
      message: 'RSS feed fetch initiated',
      last_fetched: @rss_feed.last_fetched_at
    }
  end

  # GET /api/v1/rss_feeds/:id/posts
  def posts
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    processed_filter = params[:processed]

    @posts = @rss_feed.rss_posts.recent

    # Filter by processed status
    case processed_filter
    when 'true'
      @posts = @posts.processed
    when 'false'
      @posts = @posts.unprocessed
    end

    # Pagination
    total_posts = @posts.count
    @posts = @posts.offset((page - 1) * per_page).limit(per_page)

    render json: {
      posts: @posts.map { |post| rss_post_json(post) },
      pagination: {
        page: page,
        per_page: per_page,
        total: total_posts,
        total_pages: (total_posts.to_f / per_page).ceil
      }
    }
  end

  private

  def set_rss_feed
    if current_user.super_admin?
      @rss_feed = RssFeed.find(params[:id])
    else
      @rss_feed = current_user.account.rss_feeds.find(params[:id])
    end
  end

  def require_rss_access!
    unless current_user.can_access_rss_feeds?
      render json: { error: 'RSS access not allowed for this account' }, status: :forbidden
    end
  end

  def rss_feed_params
    params.require(:rss_feed).permit(:url, :name, :description, :is_active)
  end

  def rss_feed_json(feed)
    {
      id: feed.id,
      url: feed.url,
      name: feed.name,
      description: feed.description,
      is_active: feed.is_active,
      status: feed.status,
      last_fetched_at: feed.last_fetched_at,
      posts_count: feed.rss_posts.count,
      unprocessed_posts_count: feed.unprocessed_posts.count,
      created_at: feed.created_at,
      updated_at: feed.updated_at,
      account: {
        id: feed.account.id,
        name: feed.account.name
      },
      created_by: {
        id: feed.user.id,
        name: feed.user.name,
        email: feed.user.email
      }
    }
  end

  def rss_post_json(post)
    {
      id: post.id,
      title: post.title,
      description: post.description,
      content: post.content,
      image_url: post.image_url,
      original_url: post.original_url,
      published_at: post.published_at,
      is_processed: post.is_processed,
      short_title: post.short_title,
      short_description: post.short_description,
      has_image: post.has_image?,
      display_image_url: post.display_image_url,
      social_media_content: post.social_media_content,
      formatted_published_at: post.formatted_published_at,
      relative_published_at: post.relative_published_at,
      recent: post.recent?,
      created_at: post.created_at,
      updated_at: post.updated_at
    }
  end
end
