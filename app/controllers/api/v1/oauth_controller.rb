class Api::V1::OauthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:facebook_callback, :twitter_callback, :linkedin_callback, :google_callback]
  
  # GET /api/v1/oauth/facebook/login
  # Initiates Facebook OAuth flow
  def facebook_login
    # Generate state token for CSRF protection
    state = SecureRandom.hex(16)
    session[:oauth_state] = state
    session[:user_id] = current_user.id
    
    # Facebook OAuth URL
    app_id = ENV['FACEBOOK_APP_ID']
    redirect_uri = "#{request.base_url}/api/v1/oauth/facebook/callback"
    
    permissions = [
      'email',
      'pages_manage_posts',
      'pages_read_engagement',
      'instagram_basic',
      'instagram_content_publish',
      'publish_video'
    ].join(',')
    
    oauth_url = "https://www.facebook.com/v18.0/dialog/oauth?" \
                "client_id=#{app_id}" \
                "&redirect_uri=#{CGI.escape(redirect_uri)}" \
                "&state=#{state}" \
                "&scope=#{permissions}"
    
    render json: { oauth_url: oauth_url }
  end
  
  # GET /api/v1/oauth/facebook/callback
  # Handles Facebook OAuth callback
  def facebook_callback
    code = params[:code]
    state = params[:state]
    
    # Verify state to prevent CSRF
    if state != session[:oauth_state]
      return redirect_to "#{ENV['FRONTEND_URL']}/profile?error=invalid_state"
    end
    
    user_id = session[:user_id]
    user = User.find_by(id: user_id)
    
    unless user
      return redirect_to "#{ENV['FRONTEND_URL']}/profile?error=user_not_found"
    end
    
    # Exchange code for access token
    app_id = ENV['FACEBOOK_APP_ID']
    app_secret = ENV['FACEBOOK_APP_SECRET']
    redirect_uri = "#{request.base_url}/api/v1/oauth/facebook/callback"
    
    token_url = "https://graph.facebook.com/v18.0/oauth/access_token?" \
                "client_id=#{app_id}" \
                "&redirect_uri=#{CGI.escape(redirect_uri)}" \
                "&client_secret=#{app_secret}" \
                "&code=#{code}"
    
    begin
      response = HTTParty.get(token_url)
      data = JSON.parse(response.body)
      
      if data['access_token']
        # Store the access token
        user.update!(fb_user_access_key: data['access_token'])
        
        # Redirect back to frontend with success
        redirect_to "#{ENV['FRONTEND_URL']}/profile?success=facebook_connected"
      else
        redirect_to "#{ENV['FRONTEND_URL']}/profile?error=facebook_auth_failed"
      end
    rescue => e
      Rails.logger.error "Facebook OAuth error: #{e.message}"
      redirect_to "#{ENV['FRONTEND_URL']}/profile?error=facebook_auth_failed"
    end
  end
  
  # GET /api/v1/oauth/twitter/login
  # Initiates Twitter OAuth flow
  def twitter_login
    # Twitter uses OAuth 1.0a - more complex
    # For now, return placeholder
    render json: { 
      message: 'Twitter OAuth requires OAuth 1.0a implementation',
      note: 'This will be implemented with the twitter-api gem'
    }
  end
  
  # GET /api/v1/oauth/twitter/callback
  def twitter_callback
    # Twitter OAuth 1.0a callback handler
    render json: { message: 'Twitter callback' }
  end
  
  # GET /api/v1/oauth/linkedin/login
  # Initiates LinkedIn OAuth flow
  def linkedin_login
    state = SecureRandom.hex(16)
    session[:oauth_state] = state
    session[:user_id] = current_user.id
    
    client_id = ENV['LINKEDIN_CLIENT_ID']
    redirect_uri = "#{request.base_url}/api/v1/oauth/linkedin/callback"
    
    oauth_url = "https://www.linkedin.com/oauth/v2/authorization?" \
                "response_type=code" \
                "&client_id=#{client_id}" \
                "&redirect_uri=#{CGI.escape(redirect_uri)}" \
                "&state=#{state}" \
                "&scope=w_member_social"
    
    render json: { oauth_url: oauth_url }
  end
  
  # GET /api/v1/oauth/linkedin/callback
  def linkedin_callback
    code = params[:code]
    state = params[:state]
    
    if state != session[:oauth_state]
      return redirect_to "#{ENV['FRONTEND_URL']}/profile?error=invalid_state"
    end
    
    user_id = session[:user_id]
    user = User.find_by(id: user_id)
    
    unless user
      return redirect_to "#{ENV['FRONTEND_URL']}/profile?error=user_not_found"
    end
    
    # Exchange code for access token
    client_id = ENV['LINKEDIN_CLIENT_ID']
    client_secret = ENV['LINKEDIN_CLIENT_SECRET']
    redirect_uri = "#{request.base_url}/api/v1/oauth/linkedin/callback"
    
    token_url = "https://www.linkedin.com/oauth/v2/accessToken"
    
    begin
      response = HTTParty.post(token_url, {
        body: {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: redirect_uri,
          client_id: client_id,
          client_secret: client_secret
        }
      })
      
      data = JSON.parse(response.body)
      
      if data['access_token']
        user.update!(
          linkedin_access_token: data['access_token'],
          linkedin_access_token_time: Time.current
        )
        
        redirect_to "#{ENV['FRONTEND_URL']}/profile?success=linkedin_connected"
      else
        redirect_to "#{ENV['FRONTEND_URL']}/profile?error=linkedin_auth_failed"
      end
    rescue => e
      Rails.logger.error "LinkedIn OAuth error: #{e.message}"
      redirect_to "#{ENV['FRONTEND_URL']}/profile?error=linkedin_auth_failed"
    end
  end
  
  # GET /api/v1/oauth/google/login
  # Initiates Google OAuth flow
  def google_login
    state = SecureRandom.hex(16)
    session[:oauth_state] = state
    session[:user_id] = current_user.id
    
    client_id = ENV['GOOGLE_CLIENT_ID']
    redirect_uri = "#{request.base_url}/api/v1/oauth/google/callback"
    
    oauth_url = "https://accounts.google.com/o/oauth2/v2/auth?" \
                "client_id=#{client_id}" \
                "&redirect_uri=#{CGI.escape(redirect_uri)}" \
                "&response_type=code" \
                "&scope=#{CGI.escape('https://www.googleapis.com/auth/business.manage')}" \
                "&access_type=offline" \
                "&state=#{state}"
    
    render json: { oauth_url: oauth_url }
  end
  
  # GET /api/v1/oauth/google/callback
  def google_callback
    code = params[:code]
    state = params[:state]
    
    if state != session[:oauth_state]
      return redirect_to "#{ENV['FRONTEND_URL']}/profile?error=invalid_state"
    end
    
    user_id = session[:user_id]
    user = User.find_by(id: user_id)
    
    unless user
      return redirect_to "#{ENV['FRONTEND_URL']}/profile?error=user_not_found"
    end
    
    # Exchange code for access token
    client_id = ENV['GOOGLE_CLIENT_ID']
    client_secret = ENV['GOOGLE_CLIENT_SECRET']
    redirect_uri = "#{request.base_url}/api/v1/oauth/google/callback"
    
    token_url = "https://oauth2.googleapis.com/token"
    
    begin
      response = HTTParty.post(token_url, {
        body: {
          code: code,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          grant_type: 'authorization_code'
        }
      })
      
      data = JSON.parse(response.body)
      
      if data['refresh_token']
        user.update!(google_refresh_token: data['refresh_token'])
        redirect_to "#{ENV['FRONTEND_URL']}/profile?success=google_connected"
      else
        redirect_to "#{ENV['FRONTEND_URL']}/profile?error=google_auth_failed"
      end
    rescue => e
      Rails.logger.error "Google OAuth error: #{e.message}"
      redirect_to "#{ENV['FRONTEND_URL']}/profile?error=google_auth_failed"
    end
  end
end

