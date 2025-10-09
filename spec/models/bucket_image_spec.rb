require 'rails_helper'

RSpec.describe BucketImage, type: :model do
  describe 'associations' do
    it { should belong_to(:bucket) }
    it { should belong_to(:image) }
    it { should have_many(:bucket_schedules).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:friendly_name) }
  end

  describe 'methods' do
    let(:user) { create(:user, timezone: 'America/New_York') }
    let(:bucket) { create(:bucket, user: user) }
    let(:image) { create(:image) }
    let(:bucket_image) { create(:bucket_image, bucket: bucket, image: image) }

    describe '#should_display_twitter_warning?' do
      it 'returns true for long descriptions without twitter_description' do
        bucket_image.update!(description: 'A' * 300, twitter_description: nil)
        expect(bucket_image.should_display_twitter_warning?).to be true
      end

      it 'returns false for short descriptions' do
        bucket_image.update!(description: 'Short description')
        expect(bucket_image.should_display_twitter_warning?).to be false
      end
    end

    describe '#forced_is_due?' do
      it 'returns false when no force_send_date' do
        expect(bucket_image.forced_is_due?).to be false
      end

      it 'returns true when force_send_date matches current time' do
        bucket_image.update!(force_send_date: Time.current)
        expect(bucket_image.forced_is_due?).to be true
      end
    end
  end
end
