require 'rails_helper'

RSpec.describe BucketSendHistory, type: :model do
  describe 'associations' do
    it { should belong_to(:bucket) }
    it { should belong_to(:bucket_schedule) }
    it { should belong_to(:bucket_image) }
  end

  describe 'methods' do
    let(:user) { create(:user) }
    let(:bucket) { create(:bucket, user: user) }
    let(:bucket_image) { create(:bucket_image, bucket: bucket) }
    let(:bucket_schedule) { create(:bucket_schedule, bucket: bucket, bucket_image: bucket_image) }
    let(:history) { create(:bucket_send_history, bucket: bucket, bucket_schedule: bucket_schedule, bucket_image: bucket_image, sent_to: BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER) }

    describe '#get_sent_to_name' do
      it 'converts sent_to flags to platform names' do
        expect(history.get_sent_to_name).to include('Facebook')
        expect(history.get_sent_to_name).to include('Twitter')
      end
    end
  end
end
