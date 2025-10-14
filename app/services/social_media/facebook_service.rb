module SocialMedia
  class FacebookService
    GRAPH_API_VERSION = 'v18.0'
    BASE_URL = "https://graph.facebook.com/#{GRAPH_API_VERSION}"
    
    def initialize(user)
      @user = user
    end
    
    # Post a photo to Facebook page
    # @param message [String] The post message/caption
    # @param image_url [String] Public URL of the image to post
    # @return [Hash] Response from Facebook API
    def post_photo(message, image_url)
      unless @user.fb_user_access_key.present?
        raise "User does not have Facebook connected"
      end
      
      # Get page access token
      page_token = get_page_access_token
      
      unless page_token
        raise "Could not get Facebook page access token"
      end
      
      # Determine if it's a video or photo
      extension = File.extname(image_url).downcase
      
      if ['.gif', '.mp4'].include?(extension)
        post_video(message, image_url, page_token)
      else
        post_image(message, image_url, page_token)
      end
    end
    
    # Post to Instagram (via Facebook)
    # @param message [String] The post caption
    # @param image_url [String] Public URL of the image
    # @return [Hash] Response from Instagram API
    def post_to_instagram(message, image_url)
      unless @user.instagram_business_id.present?
        raise "User does not have Instagram connected"
      end
      
      page_token = get_page_access_token
      
      unless page_token
        raise "Could not get Facebook page access token for Instagram"
      end
      
      # Step 1: Create media container
      create_url = "#{BASE_URL}/#{@user.instagram_business_id}/media"
      create_params = {
        image_url: image_url,
        caption: message,
        access_token: page_token
      }
      
      response = HTTParty.post(create_url, body: create_params)
      data = JSON.parse(response.body)
      
      unless data['id']
        raise "Failed to create Instagram media container: #{data['error']}"
      end
      
      creation_id = data['id']
      
      # Step 2: Publish the media
      publish_url = "#{BASE_URL}/#{@user.instagram_business_id}/media_publish"
      publish_params = {
        creation_id: creation_id,
        access_token: page_token
      }
      
      response = HTTParty.post(publish_url, body: publish_params)
      JSON.parse(response.body)
    end
    
    private
    
    # Post an image to Facebook
    def post_image(message, image_url, page_token)
      url = "#{BASE_URL}/me/photos"
      params = {
        message: message,
        url: image_url,
        access_token: page_token
      }
      
      response = HTTParty.post(url, body: params)
      JSON.parse(response.body)
    end
    
    # Post a video to Facebook
    def post_video(message, video_url, page_token)
      url = "#{BASE_URL}/me/videos"
      params = {
        description: message,
        file_url: video_url,
        access_token: page_token
      }
      
      response = HTTParty.post(url, body: params)
      JSON.parse(response.body)
    end
    
    # Get the page access token from user's access token
    # In production, you'd fetch the user's pages and let them select one
    # For now, we'll use the first page
    def get_page_access_token
      url = "#{BASE_URL}/me/accounts"
      params = {
        access_token: @user.fb_user_access_key,
        limit: 1000
      }
      
      response = HTTParty.get(url, query: params)
      data = JSON.parse(response.body)
      
      if data['data'] && data['data'].any?
        # Return the first page's access token
        data['data'].first['access_token']
      else
        nil
      end
    end
  end
end

