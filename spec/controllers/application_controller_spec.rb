require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Create a test controller to test ApplicationController methods
  controller do
    def index
      render json: { message: 'success' }
    end
  end

  describe 'authentication' do
    context 'with valid token' do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:decode_token).and_return(user.id)
        request.headers['Authorization'] = 'Bearer valid_token'
      end

      it 'allows access with valid token' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(controller.send(:current_user)).to eq(user)
      end
    end

    context 'without token' do
      it 'denies access without token' do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Authentication token required')
      end
    end

    context 'with invalid token' do
      before do
        allow(controller).to receive(:decode_token).and_raise(StandardError.new('Invalid token'))
        request.headers['Authorization'] = 'Bearer invalid_token'
      end

      it 'denies access with invalid token' do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid authentication token')
      end
    end
  end

  describe 'error handling' do
    before do
      allow(controller).to receive(:authenticate_user!).and_return(true)
      allow(controller).to receive(:current_user).and_return(create(:user))
    end

    context 'ActiveRecord::RecordNotFound' do
      controller do
        def index
          User.find(99999)
        end
      end

      it 'handles record not found' do
        get :index
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end

    context 'ActiveRecord::RecordInvalid' do
      controller do
        def index
          User.create!(name: '') # This will fail validation
        end
      end

      it 'handles record invalid' do
        get :index
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Validation failed')
        expect(json_response['details']).to be_present
      end
    end

    context 'ActionController::ParameterMissing' do
      controller do
        def index
          params.require(:missing_param)
        end
      end

      it 'handles parameter missing' do
        get :index
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing required parameter')
        expect(json_response['parameter']).to eq('missing_param')
      end
    end
  end
end

