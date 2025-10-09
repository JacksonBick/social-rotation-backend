class ApplicationController < ActionController::API
  include ActionController::Cookies

  # Skip CSRF for API (use token authentication instead)
  # protect_from_forgery with: :null_session

  # Handle authentication
  before_action :authenticate_user!

  # Handle exceptions
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  # Authenticate user using JWT token from Authorization header
  # Expects: "Authorization: Bearer <token>"
  # Sets @current_user if valid token
  # Returns 401 if missing or invalid token
  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token.blank?
      render json: { error: 'Authentication token required' }, status: :unauthorized
      return
    end

    decoded = JsonWebToken.decode(token)
    
    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
      
      unless @current_user
        render json: { error: 'User not found' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  rescue => e
    render json: { error: 'Authentication failed' }, status: :unauthorized
  end

  protected

  # Get current authenticated user
  # Available in all controllers after authenticate_user! runs
  def current_user
    @current_user
  end

  def record_not_found(exception)
    render json: { error: 'Record not found' }, status: :not_found
  end

  def record_invalid(exception)
    render json: { 
      error: 'Validation failed', 
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end

  def parameter_missing(exception)
    render json: { 
      error: 'Missing required parameter', 
      parameter: exception.param 
    }, status: :bad_request
  end
end