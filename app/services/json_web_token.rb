# JWT Service - handles encoding and decoding of JSON Web Tokens
# Used for user authentication and session management
class JsonWebToken
  # Secret key for signing tokens (should be in ENV in production)
  SECRET_KEY = Rails.application.credentials.secret_key_base || 'your-secret-key'

  # Encode user data into a JWT token
  # Params:
  #   payload - Hash of data to encode (usually { user_id: user.id })
  #   exp - Expiration time (default: 24 hours from now)
  # Returns: JWT token string
  # Example: JsonWebToken.encode({ user_id: 1 })
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  # Decode a JWT token back into user data
  # Params:
  #   token - JWT token string
  # Returns: Hash with decoded data or nil if invalid/expired
  # Example: JsonWebToken.decode('eyJhbGciOiJIUzI1NiJ9...')
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
