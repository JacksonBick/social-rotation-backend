require 'rails_helper'

RSpec.describe Bucket, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:bucket_images).dependent(:destroy) }
    it { should have_many(:bucket_schedules).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'scopes' do
    describe '.is_market' do
      it 'returns buckets with account_id 0' do
        market_bucket = create(:bucket, account_id: 0)
        regular_bucket = create(:bucket, account_id: 1)

        expect(Bucket.is_market).to include(market_bucket)
        expect(Bucket.is_market).not_to include(regular_bucket)
      end
    end
  end

  describe 'methods' do
    let(:user) { create(:user, account_id: 1) }
    let(:bucket) { create(:bucket, user: user) }

    describe '#is_market_bucket?' do
      it 'returns true when user account_id is 0' do
        user.update!(account_id: 0)
        expect(bucket.is_market_bucket?).to be true
      end

      it 'returns false when user account_id is not 0' do
        expect(bucket.is_market_bucket?).to be false
      end
    end

    describe '#is_due' do
      it 'returns nil when no bucket schedules exist' do
        expect(bucket.is_due(Time.current)).to be_nil
      end

      it 'returns nil when schedule is disabled' do
        create(:bucket_schedule, bucket: bucket, schedule: '0 0 0 0 0')
        expect(bucket.is_due(Time.current)).to be_nil
      end
    end

    describe '#get_next_rotation_image' do
      let(:image1) { create(:image, friendly_name: 'A') }
      let(:image2) { create(:image, friendly_name: 'B') }
      let!(:bucket_image1) { create(:bucket_image, bucket: bucket, image: image1, friendly_name: 'A') }
      let!(:bucket_image2) { create(:bucket_image, bucket: bucket, image: image2, friendly_name: 'B') }

      it 'returns nil when no rotation schedules exist' do
        expect(bucket.get_next_rotation_image).to be_nil
      end

      it 'returns the first image when no previous sends' do
        create(:bucket_schedule, bucket: bucket, schedule_type: BucketSchedule::SCHEDULE_TYPE_ROTATION)
        expect(bucket.get_next_rotation_image).to eq(bucket_image1)
      end
    end
  end
end