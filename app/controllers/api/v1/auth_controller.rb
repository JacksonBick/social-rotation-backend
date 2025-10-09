# Authentication Controller
# Handles user registration and login
# Endpoints:
#   POST /api/v1/auth/register - Create new user account
#   POST /api/v1/auth/login - Authenticate existing user
class Api::V1::AuthController < ApplicationController
  # Skip authentication for auth endpoints (otherwise can't login!)
  skip_before_action :authenticate_user!, only: [:register, :login]

  # POST /api/v1/auth/register
  # Create new user account
  # Params: name, email, password, password_confirmation
  # Returns: user object and JWT token
  def register
    user = User.new(user_params)
    
    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        user: user_json(user),
        token: token,
        message: 'Account created successfully'
      }, status: :created
    else
      render json: {
        error: 'Registration failed',
        details: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/login
  # Authenticate user with email and password
  # Params: email, password
  # Returns: user object and JWT token
  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        user: user_json(user),
        token: token,
        message: 'Login successful'
      }
    else
      render json: {
        error: 'Invalid email or password'
      }, status: :unauthorized
    end
  end

  private

  # Permit only safe user parameters
  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  # Format user data for JSON response (exclude sensitive fields)
  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at
    }
  end
end
