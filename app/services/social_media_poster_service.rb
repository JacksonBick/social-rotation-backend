class SocialMediaPosterService
  # Social media platform bit flags (from BucketSchedule model)
  BIT_FACEBOOK = 1
  BIT_TWITTER = 2
  BIT_INSTAGRAM = 4
  BIT_LINKEDIN = 8
  BIT_GMB = 16
  BIT_PINTEREST = 32
  
  def initialize(user, bucket_image, post_to_flags, description, twitter_description = nil)
    @user = user
    @bucket_image = bucket_image
    @post_to = post_to_flags
    @description = description
    @twitter_description = twitter_description || description
  end
  
  # Post to all selected social media platforms
  # @return [Hash] Results from each platform
  def post_to_all
    results = {}
    
    # Get image URL (needs to be publicly accessible)
    image_url = get_public_image_url
    image_path = get_local_image_path
    
    # Post to Facebook
    if should_post_to?(BIT_FACEBOOK)
      results[:facebook] = post_to_facebook(image_url)
    end
    
    # Post to Twitter
    if should_post_to?(BIT_TWITTER)
      results[:twitter] = post_to_twitter(image_path)
    end
    
    # Post to Instagram
    if should_post_to?(BIT_INSTAGRAM)
      results[:instagram] = post_to_instagram(image_url)
    end
    
    # Post to LinkedIn
    if should_post_to?(BIT_LINKEDIN)
      results[:linkedin] = post_to_linkedin(image_path)
    end
    
    # Post to Google My Business
    if should_post_to?(BIT_GMB)
      results[:gmb] = post_to_gmb(image_url)
    end
    
    results
  end
  
  private
  
  # Check if should post to a specific platform
  # @param bit_flag [Integer] Platform bit flag
  # @return [Boolean]
  def should_post_to?(bit_flag)
    (@post_to & bit_flag) != 0
  end
  
  # Get public URL for the image
  # @return [String] Public URL
  def get_public_image_url
    # For local development
    if Rails.env.development?
      "http://localhost:3000/#{@bucket_image.image.file_path}"
    else
      # For production with Digital Ocean Spaces
      @bucket_image.image.get_source_url
    end
  end
  
  # Get local file path for the image
  # @return [String] Local file path
  def get_local_image_path
    Rails.root.join('public', @bucket_image.image.file_path).to_s
  end
  
  # Post to Facebook
  def post_to_facebook(image_url)
    begin
      service = SocialMedia::FacebookService.new(@user)
      response = service.post_photo(@description, image_url)
      
      { success: true, response: response }
    rescue => e
      Rails.logger.error "Facebook posting error: #{e.message}"
      { success: false, error: e.message }
    end
  end
  
  # Post to Twitter
  def post_to_twitter(image_path)
    begin
      service = SocialMedia::TwitterService.new(@user)
      response = service.post_tweet(@twitter_description, image_path)
      
      { success: true, response: response }
    rescue => e
      Rails.logger.error "Twitter posting error: #{e.message}"
      { success: false, error: e.message }
    end
  end
  
  # Post to Instagram
  def post_to_instagram(image_url)
    begin
      service = SocialMedia::FacebookService.new(@user)
      response = service.post_to_instagram(@description, image_url)
      
      { success: true, response: response }
    rescue => e
      Rails.logger.error "Instagram posting error: #{e.message}"
      { success: false, error: e.message }
    end
  end
  
  # Post to LinkedIn
  def post_to_linkedin(image_path)
    begin
      service = SocialMedia::LinkedinService.new(@user)
      response = service.post_with_image(@description, image_path)
      
      { success: true, response: response }
    rescue => e
      Rails.logger.error "LinkedIn posting error: #{e.message}"
      { success: false, error: e.message }
    end
  end
  
  # Post to Google My Business
  def post_to_gmb(image_url)
    begin
      service = SocialMedia::GoogleService.new(@user)
      response = service.post_to_gmb(@description, image_url)
      
      { success: true, response: response }
    rescue => e
      Rails.logger.error "Google My Business posting error: #{e.message}"
      { success: false, error: e.message }
    end
  end
end

