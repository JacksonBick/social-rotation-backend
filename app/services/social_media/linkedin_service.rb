module SocialMedia
  class LinkedinService
    API_BASE_URL = 'https://api.linkedin.com/v2'
    
    def initialize(user)
      @user = user
    end
    
    # Post to LinkedIn with image
    # @param message [String] Post text
    # @param image_path [String] Local path to image file
    # @return [Hash] Response from LinkedIn API
    def post_with_image(message, image_path)
      unless @user.linkedin_access_token.present?
        raise "User does not have LinkedIn connected"
      end
      
      unless @user.linkedin_profile_id.present?
        # Fetch profile ID if not stored
        fetch_profile_id
      end
      
      # Step 1: Register upload
      asset_urn = register_upload
      
      # Step 2: Upload image
      upload_image(asset_urn, image_path)
      
      # Step 3: Create post
      create_post(message, asset_urn)
    end
    
    private
    
    # Fetch user's LinkedIn profile ID
    def fetch_profile_id
      url = "#{API_BASE_URL}/me"
      headers = {
        'Authorization' => "Bearer #{@user.linkedin_access_token}",
        'X-Restli-Protocol-Version' => '2.0.0'
      }
      
      response = HTTParty.get(url, headers: headers)
      data = JSON.parse(response.body)
      
      if data['id']
        @user.update!(linkedin_profile_id: data['id'])
      else
        raise "Failed to fetch LinkedIn profile ID"
      end
    end
    
    # Register an upload with LinkedIn
    # @return [String] Asset URN
    def register_upload
      url = "#{API_BASE_URL}/assets?action=registerUpload"
      headers = {
        'Authorization' => "Bearer #{@user.linkedin_access_token}",
        'Content-Type' => 'application/json',
        'X-Restli-Protocol-Version' => '2.0.0'
      }
      
      body = {
        registerUploadRequest: {
          recipes: ['urn:li:digitalmediaRecipe:feedshare-image'],
          owner: "urn:li:person:#{@user.linkedin_profile_id}",
          serviceRelationships: [
            {
              relationshipType: 'OWNER',
              identifier: 'urn:li:userGeneratedContent'
            }
          ]
        }
      }
      
      response = HTTParty.post(url, headers: headers, body: body.to_json)
      data = JSON.parse(response.body)
      
      if data['value']
        upload_url = data['value']['uploadMechanism']['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']['uploadUrl']
        asset_urn = data['value']['asset']
        
        # Store upload URL for next step
        @upload_url = upload_url
        
        asset_urn
      else
        raise "Failed to register LinkedIn upload: #{data['message']}"
      end
    end
    
    # Upload image to LinkedIn
    # @param asset_urn [String] Asset URN from registration
    # @param image_path [String] Local path to image
    def upload_image(asset_urn, image_path)
      headers = {
        'Authorization' => "Bearer #{@user.linkedin_access_token}",
        'X-Restli-Protocol-Version' => '2.0.0'
      }
      
      # Read image file
      image_data = File.read(image_path)
      
      response = HTTParty.post(@upload_url, 
        headers: headers,
        body: image_data
      )
      
      unless response.success?
        raise "Failed to upload image to LinkedIn"
      end
    end
    
    # Create LinkedIn post
    # @param message [String] Post text
    # @param asset_urn [String] Asset URN of uploaded image
    # @return [Hash] Response from LinkedIn API
    def create_post(message, asset_urn)
      url = "#{API_BASE_URL}/ugcPosts"
      headers = {
        'Authorization' => "Bearer #{@user.linkedin_access_token}",
        'Content-Type' => 'application/json',
        'X-Restli-Protocol-Version' => '2.0.0'
      }
      
      body = {
        author: "urn:li:person:#{@user.linkedin_profile_id}",
        lifecycleState: 'PUBLISHED',
        specificContent: {
          'com.linkedin.ugc.ShareContent' => {
            shareCommentary: {
              text: message
            },
            shareMediaCategory: 'IMAGE',
            media: [
              {
                status: 'READY',
                description: {
                  text: message
                },
                media: asset_urn,
                title: {
                  text: message
                }
              }
            ]
          }
        },
        visibility: {
          'com.linkedin.ugc.MemberNetworkVisibility' => 'PUBLIC'
        }
      }
      
      response = HTTParty.post(url, headers: headers, body: body.to_json)
      JSON.parse(response.body)
    end
  end
end

