# Test suite for AccountFeature model
# Tests: associations, validations, default values
require 'rails_helper'

RSpec.describe AccountFeature, type: :model do
  # Test: AccountFeature factory creates a valid record
  describe 'factory' do
    it 'has a valid factory' do
      account_feature = build(:account_feature)
      expect(account_feature).to be_valid
    end
  end

  # Test: AccountFeature associations
  describe 'associations' do
    it { should belong_to(:account) }
  end

  # Test: AccountFeature validations
  describe 'validations' do
    it { should validate_presence_of(:account) }
    it { should validate_numericality_of(:max_users).is_greater_than(0) }
    it { should validate_numericality_of(:max_buckets).is_greater_than(0) }
    it { should validate_numericality_of(:max_images_per_bucket).is_greater_than(0) }
  end

  # Test: Default values are set correctly
  describe 'default values' do
    let(:account) { create(:account) }
    let(:account_feature) { account.account_feature }

    it 'sets default max_users to 50' do
      expect(account_feature.max_users).to eq(50)
    end

    it 'sets default max_buckets to 100' do
      expect(account_feature.max_buckets).to eq(100)
    end

    it 'sets default max_images_per_bucket to 1000' do
      expect(account_feature.max_images_per_bucket).to eq(1000)
    end

    it 'enables marketplace by default' do
      expect(account_feature.allow_marketplace).to be true
    end

    it 'enables RSS by default' do
      expect(account_feature.allow_rss).to be true
    end

    it 'enables integrations by default' do
      expect(account_feature.allow_integrations).to be true
    end

    it 'enables watermark by default' do
      expect(account_feature.allow_watermark).to be true
    end
  end

  # Test: Invalid numeric values are rejected
  describe 'numeric validations' do
    let(:account) { create(:account) }

    it 'rejects zero max_users' do
      account_feature = build(:account_feature, account: account, max_users: 0)
      expect(account_feature).not_to be_valid
      expect(account_feature.errors[:max_users]).to be_present
    end

    it 'rejects negative max_buckets' do
      account_feature = build(:account_feature, account: account, max_buckets: -1)
      expect(account_feature).not_to be_valid
      expect(account_feature.errors[:max_buckets]).to be_present
    end

    it 'rejects zero max_images_per_bucket' do
      account_feature = build(:account_feature, account: account, max_images_per_bucket: 0)
      expect(account_feature).not_to be_valid
      expect(account_feature.errors[:max_images_per_bucket]).to be_present
    end
  end
end
