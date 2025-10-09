require 'rails_helper'

RSpec.describe Image, type: :model do
  describe 'associations' do
    it { should have_many(:bucket_images).dependent(:destroy) }
    it { should have_many(:buckets).through(:bucket_images) }
  end

  describe 'validations' do
    it { should validate_presence_of(:file_path) }
  end

  describe 'methods' do
    let(:image) { create(:image, file_path: 'test/image.jpg') }

    describe '#get_source_url' do
      it 'generates source URL' do
        expect(image.get_source_url).to eq('https://se1.sfo2.digitaloceanspaces.com/test/image.jpg')
      end
    end
  end
end
