require 'rails_helper'

RSpec.describe BucketSchedule, type: :model do
  describe 'constants' do
    it 'has correct schedule type constants' do
      expect(BucketSchedule::SCHEDULE_TYPE_ROTATION).to eq(1)
      expect(BucketSchedule::SCHEDULE_TYPE_ONCE).to eq(2)
      expect(BucketSchedule::SCHEDULE_TYPE_ANNUALLY).to eq(3)
    end

    it 'has correct social media bit flags' do
      expect(BucketSchedule::BIT_FACEBOOK).to eq(1)
      expect(BucketSchedule::BIT_TWITTER).to eq(2)
      expect(BucketSchedule::BIT_INSTAGRAM).to eq(4)
      expect(BucketSchedule::BIT_LINKEDIN).to eq(8)
      expect(BucketSchedule::BIT_GMB).to eq(16)
    end
  end

  describe 'associations' do
    it { should belong_to(:bucket) }
    it { should belong_to(:bucket_image).optional }
    it { should have_many(:bucket_send_histories).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:schedule) }
    it { should validate_presence_of(:schedule_type) }
    it { should validate_inclusion_of(:schedule_type).in_array([BucketSchedule::SCHEDULE_TYPE_ROTATION, BucketSchedule::SCHEDULE_TYPE_ONCE, BucketSchedule::SCHEDULE_TYPE_ANNUALLY]) }
    
    it 'validates cron format' do
      valid_schedule = create(:bucket_schedule, schedule: '0 9 * * 1-5')
      expect(valid_schedule).to be_valid
      
      invalid_schedule = build(:bucket_schedule, schedule: 'invalid cron')
      expect(invalid_schedule).not_to be_valid
      expect(invalid_schedule.errors[:schedule]).to include(/must have exactly 5 space-separated parts/)
    end
  end

  describe 'methods' do
    let(:user) { create(:user, timezone: 'America/New_York') }
    let(:bucket) { create(:bucket, user: user) }
    let(:bucket_image) { create(:bucket_image, bucket: bucket) }
    let(:bucket_schedule) { create(:bucket_schedule, bucket: bucket, bucket_image: bucket_image) }

    describe '#get_type_image' do
      it 'returns correct image for rotation type' do
        bucket_schedule.update!(schedule_type: BucketSchedule::SCHEDULE_TYPE_ROTATION)
        expect(bucket_schedule.get_type_image).to eq('rotation.png')
      end

      it 'returns correct image for once type' do
        bucket_schedule.update!(schedule_type: BucketSchedule::SCHEDULE_TYPE_ONCE)
        expect(bucket_schedule.get_type_image).to eq('post_once.png')
      end

      it 'returns correct image for annually type' do
        bucket_schedule.update!(schedule_type: BucketSchedule::SCHEDULE_TYPE_ANNUALLY)
        expect(bucket_schedule.get_type_image).to eq('annual.png')
      end
    end

    describe '#can_send?' do
      it 'returns true for schedules without history' do
        expect(bucket_schedule.can_send?).to be true
      end
    end

    describe '#is_network_selected?' do
      it 'returns true for selected networks' do
        bucket_schedule.update!(post_to: BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER)
        expect(bucket_schedule.is_network_selected?(BucketSchedule::BIT_FACEBOOK)).to be true
        expect(bucket_schedule.is_network_selected?(BucketSchedule::BIT_TWITTER)).to be true
        expect(bucket_schedule.is_network_selected?(BucketSchedule::BIT_LINKEDIN)).to be false
      end
    end

    describe '#get_posts_to_images' do
      it 'returns correct image states for selected platforms' do
        bucket_schedule.update!(post_to: BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER)
        result = bucket_schedule.get_posts_to_images

        expect(result['Facebook']).to eq('facebook_on.png')
        expect(result['Twitter']).to eq('twitter_on.png')
        expect(result['LinkedIn']).to eq('linkedin_off.png')
      end
    end

    describe '#get_days_selected' do
      it 'returns days from cron expression' do
        bucket_schedule.update!(schedule: '0 9 * * 1,3,5')
        expect(bucket_schedule.get_days_selected).to eq(['1', '3', '5'])
      end

      it 'returns empty array for invalid schedule' do
        bucket_schedule.schedule = nil
        expect(bucket_schedule.get_days_selected).to eq([])
      end
    end

    describe '#is_day_selected?' do
      it 'returns true for selected days' do
        bucket_schedule.update!(schedule: '0 9 * * 1,3,5')
        expect(bucket_schedule.is_day_selected?(1)).to be true
        expect(bucket_schedule.is_day_selected?(3)).to be true
        expect(bucket_schedule.is_day_selected?(2)).to be false
      end

      it 'returns true for wildcard days' do
        bucket_schedule.update!(schedule: '0 9 * * *')
        expect(bucket_schedule.is_day_selected?(1)).to be true
        expect(bucket_schedule.is_day_selected?(7)).to be true
      end
    end

    describe '#get_time_format' do
      it 'returns time from cron expression' do
        bucket_schedule.update!(schedule: '30 14 * * *')
        expect(bucket_schedule.get_time_format).to eq('14:30')
      end

      it 'returns default time for wildcard schedule' do
        bucket_schedule.update!(schedule: '* * * * *')
        expect(bucket_schedule.get_time_format).to eq('12:00')
      end
    end

    describe '#get_next_bucket_image_due' do
      it 'returns bucket_image for once and annually schedules' do
        once_schedule = create(:bucket_schedule, bucket: bucket, bucket_image: bucket_image, schedule_type: BucketSchedule::SCHEDULE_TYPE_ONCE)
        expect(once_schedule.get_next_bucket_image_due).to eq(bucket_image)

        annual_schedule = create(:bucket_schedule, bucket: bucket, bucket_image: bucket_image, schedule_type: BucketSchedule::SCHEDULE_TYPE_ANNUALLY)
        expect(annual_schedule.get_next_bucket_image_due).to eq(bucket_image)
      end
    end
  end
end