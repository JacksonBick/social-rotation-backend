require 'rails_helper'

RSpec.describe Api::V1::BucketSchedulesController, type: :controller do
  let(:user) { create(:user) }
  let(:bucket) { create(:bucket, user: user) }
  let(:bucket_image) { create(:bucket_image, bucket: bucket) }
  let(:bucket_schedule) { create(:bucket_schedule, bucket: bucket, bucket_image: bucket_image) }

  before do
    # Mock authentication
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    before do
      create(:bucket_schedule, bucket: bucket)
      create(:bucket_schedule, bucket: bucket)
      create(:bucket_schedule) # Different user
    end

    it 'returns all bucket schedules for current user' do
      get :index

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['bucket_schedules'].length).to eq(2)
    end
  end

  describe 'GET #show' do
    it 'returns bucket schedule details' do
      get :show, params: { id: bucket_schedule.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['bucket_schedule']['id']).to eq(bucket_schedule.id)
      expect(json_response['bucket_schedule']['schedule']).to eq(bucket_schedule.schedule)
    end

    it 'returns 404 for non-existent schedule' do
      get :show, params: { id: 99999 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    let(:create_params) do
      {
        bucket_id: bucket.id,
        bucket_schedule: {
          schedule: '0 9 * * 1-5',
          schedule_type: BucketSchedule::SCHEDULE_TYPE_ROTATION,
          post_to: BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER
        }
      }
    end

    it 'creates a new bucket schedule' do
      expect {
        post :create, params: create_params
      }.to change(BucketSchedule, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['bucket_schedule']['schedule']).to eq('0 9 * * 1-5')
    end

    it 'returns errors for invalid parameters' do
      invalid_params = { bucket_id: bucket.id, bucket_schedule: { schedule: '' } }
      
      post :create, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: bucket_schedule.id,
        bucket_schedule: {
          schedule: '0 10 * * 1-5',
          post_to: BucketSchedule::BIT_INSTAGRAM
        }
      }
    end

    it 'updates the bucket schedule' do
      patch :update, params: update_params

      expect(response).to have_http_status(:ok)
      bucket_schedule.reload
      expect(bucket_schedule.schedule).to eq('0 10 * * 1-5')
      expect(bucket_schedule.post_to).to eq(BucketSchedule::BIT_INSTAGRAM)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the bucket schedule' do
      # Create the schedule before the expect block
      schedule_id = bucket_schedule.id
      
      expect {
        delete :destroy, params: { id: schedule_id }
      }.to change(BucketSchedule, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Schedule deleted successfully')
    end
  end

  describe 'POST #bulk_update' do
    let(:schedule1) { create(:bucket_schedule, bucket: bucket) }
    let(:schedule2) { create(:bucket_schedule, bucket: bucket) }
    let(:bulk_params) do
      {
        bucket_schedule_ids: "#{schedule1.id},#{schedule2.id}",
        networks: ['facebook', 'twitter'],
        time: '2024-12-25 10:00 AM'
      }
    end

    it 'updates multiple schedules' do
      post :bulk_update, params: bulk_params

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('2 schedules successfully updated')

      schedule1.reload
      schedule2.reload
      expected_post_to = BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER
      expect(schedule1.post_to).to eq(expected_post_to)
      expect(schedule2.post_to).to eq(expected_post_to)
    end

    it 'returns error for invalid time format' do
      invalid_params = bulk_params.merge(time: 'invalid time')
      
      post :bulk_update, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE #bulk_delete' do
    let(:schedule1) { create(:bucket_schedule, bucket: bucket) }
    let(:schedule2) { create(:bucket_schedule, bucket: bucket) }

    it 'deletes multiple schedules' do
      # Force creation before the expect block
      id1 = schedule1.id
      id2 = schedule2.id
      
      bulk_params = {
        bucket_schedule_ids: "#{id1},#{id2}"
      }
      
      expect {
        post :bulk_delete, params: bulk_params
      }.to change(BucketSchedule, :count).by(-2)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('2 schedules successfully deleted')
    end
  end

  describe 'POST #rotation_create' do
    let(:rotation_params) do
      {
        bucket_id: bucket.id,
        networks: ['facebook', 'instagram'],
        time: '09:00',
        days: ['1', '2', '3', '4', '5'] # Monday to Friday
      }
    end

    it 'creates a rotation schedule' do
      expect {
        post :rotation_create, params: rotation_params
      }.to change(BucketSchedule, :count).by(1)

      expect(response).to have_http_status(:ok)
      schedule = BucketSchedule.last
      expect(schedule.schedule_type).to eq(BucketSchedule::SCHEDULE_TYPE_ROTATION)
      expect(schedule.schedule).to eq('0 9 * * 1,2,3,4,5')
      expect(schedule.post_to).to eq(BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_INSTAGRAM)
    end

    it 'returns error for missing parameters' do
      invalid_params = { bucket_id: bucket.id, networks: ['facebook'] }
      
      post :rotation_create, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #date_create' do
    let(:date_params) do
      {
        bucket_id: bucket.id,
        bucket_image_id: bucket_image.id,
        networks: ['twitter', 'linked_in'],
        time: '2024-12-25 10:00 AM',
        description: 'Holiday post',
        twitter_description: 'Holiday tweet'
      }
    end

    it 'creates a date-based schedule' do
      expect {
        post :date_create, params: date_params
      }.to change(BucketSchedule, :count).by(1)

      expect(response).to have_http_status(:ok)
      schedule = BucketSchedule.last
      expect(schedule.schedule_type).to eq(BucketSchedule::SCHEDULE_TYPE_ONCE)
      expect(schedule.bucket_image).to eq(bucket_image)
      expect(schedule.description).to eq('Holiday post')
      expect(schedule.twitter_description).to eq('Holiday tweet')
    end

    it 'creates annually schedule when requested' do
      annually_params = date_params.merge(post_annually: 'true')
      
      post :date_create, params: annually_params

      schedule = BucketSchedule.last
      expect(schedule.schedule_type).to eq(BucketSchedule::SCHEDULE_TYPE_ANNUALLY)
    end
  end

  describe 'POST #post_now' do
    it 'increments times_sent counter' do
      expect {
        post :post_now, params: { id: bucket_schedule.id }
      }.to change { bucket_schedule.reload.times_sent }.by(1)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Post sent successfully')
    end
  end

  describe 'POST #skip_image' do
    it 'increments skip_image counter' do
      expect {
        post :skip_image, params: { id: bucket_schedule.id }
      }.to change { bucket_schedule.reload.skip_image }.by(1)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Image skipped')
    end
  end

  describe 'POST #skip_image_single' do
    context 'with annually schedule' do
      let(:annually_schedule) { create(:bucket_schedule, bucket: bucket, schedule_type: BucketSchedule::SCHEDULE_TYPE_ANNUALLY) }

      it 'sets skip_image to 1' do
        post :skip_image_single, params: { id: annually_schedule.id }

        expect(response).to have_http_status(:ok)
        annually_schedule.reload
        expect(annually_schedule.skip_image).to eq(1)
      end
    end

    context 'with once schedule' do
      let(:once_schedule) { create(:bucket_schedule, bucket: bucket, schedule_type: BucketSchedule::SCHEDULE_TYPE_ONCE) }

      it 'deletes the schedule' do
        # Create the schedule before the expect block
        schedule_id = once_schedule.id
        
        expect {
          post :skip_image_single, params: { id: schedule_id }
        }.to change(BucketSchedule, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #history' do
    before do
      create(:bucket_send_history, bucket_schedule: bucket_schedule, sent_at: 1.day.ago)
      create(:bucket_send_history, bucket_schedule: bucket_schedule, sent_at: 2.days.ago)
    end

    it 'returns send history for the schedule' do
      get :history, params: { id: bucket_schedule.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['send_histories'].length).to eq(2)
      expect(json_response['bucket_schedule']['id']).to eq(bucket_schedule.id)
    end
  end

  describe 'network flag calculation' do
    it 'correctly calculates post_to flags for all networks' do
      all_networks = ['facebook', 'twitter', 'instagram', 'linked_in', 'google_business']
      expected_flags = BucketSchedule::BIT_FACEBOOK | 
                      BucketSchedule::BIT_TWITTER | 
                      BucketSchedule::BIT_INSTAGRAM | 
                      BucketSchedule::BIT_LINKEDIN | 
                      BucketSchedule::BIT_GMB

      params = {
        bucket_id: bucket.id,
        networks: all_networks,
        time: '09:00',
        days: ['1', '2', '3', '4', '5']
      }

      post :rotation_create, params: params

      schedule = BucketSchedule.last
      expect(schedule.post_to).to eq(expected_flags)
    end
  end
end

