require 'rails_helper'

RSpec.describe UserMarketItem, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:market_item) }
  end
end

