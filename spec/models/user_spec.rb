require 'rails_helper'

# User Model Tests
# Validates: associations, validations, password security, and watermark path generation
RSpec.describe User, type: :model do
  
  # TEST: User associations are properly configured
  # Verify user has many buckets and videos, both destroy on user deletion
  describe 'associations' do
    # Should have many buckets that are destroyed when user is deleted
    it { should have_many(:buckets).dependent(:destroy) }
    # Should have many videos that are destroyed when user is deleted
    it { should have_many(:videos).dependent(:destroy) }
  end

  # TEST: User validations work correctly
  # Verify email and name are required, email is unique
  describe 'validations' do
    # Email field must be present
    it { should validate_presence_of(:email) }
    # Name field must be present
    it { should validate_presence_of(:name) }
    # Email must be unique across all users
    it { should validate_uniqueness_of(:email) }
  end

  # TEST: Password authentication using bcrypt
  # Verify user can set password and authenticate correctly
  describe 'password security' do
    # Test: Create user with password, verify authentication works
    # Should authenticate with correct password, reject incorrect password
    it 'has secure password' do
      # Create new user with email and name
      user = User.new(email: 'test@example.com', name: 'Test User')
      # Set password and confirmation (required by has_secure_password)
      user.password = 'password123'
      user.password_confirmation = 'password123'
      user.save!

      # Correct password should return the user object
      expect(user.authenticate('password123')).to eq(user)
      # Wrong password should return false
      expect(user.authenticate('wrong_password')).to be_falsey
    end
  end

  # TEST: Watermark path generation methods
  # Verify all watermark path methods generate correct URLs/paths
  describe 'watermark methods' do
    # Create test user with watermark logo
    let(:user) { create(:user, watermark_logo: 'test_logo.png') }

    # Test: All watermark path methods generate valid paths with correct structure
    it 'generates watermark paths correctly' do
      # Preview path should be standard URL
      expect(user.get_watermark_preview).to eq('/user/standard_preview')
      # Digital Ocean path should include CDN URL
      expect(user.get_digital_ocean_watermark_path).to include('se1.sfo2.digitaloceanspaces.com')
      # Local storage path should include /storage/ directory
      expect(user.get_watermark_logo).to include('/storage/')
    end

    # Test: When watermark logo is nil, methods return empty strings
    # Prevents errors when user hasn't uploaded a watermark
    it 'handles missing watermark logo' do
      # Remove watermark logo
      user.watermark_logo = nil
      # Should return empty string for Digital Ocean path
      expect(user.get_digital_ocean_watermark_path).to eq('')
      # Should return empty string for local storage path
      expect(user.get_watermark_logo).to eq('')
    end
  end
end