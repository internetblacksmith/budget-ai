require 'rails_helper'

RSpec.describe ChatMessage, type: :model do
  describe 'validations' do
    it 'validates presence of role' do
      message = build(:chat_message, role: nil)
      expect(message).not_to be_valid
      expect(message.errors[:role]).to include("can't be blank")
    end

    it 'validates role inclusion' do
      message = build(:chat_message, role: "system")
      expect(message).not_to be_valid
      expect(message.errors[:role]).to include("is not included in the list")
    end

    it 'validates presence of content' do
      message = build(:chat_message, content: nil)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end

    it 'is valid with role user' do
      message = build(:chat_message, role: "user")
      expect(message).to be_valid
    end

    it 'is valid with role assistant' do
      message = build(:chat_message, role: "assistant")
      expect(message).to be_valid
    end
  end

  describe '.chronological' do
    it 'orders by created_at ascending' do
      old_message = create(:chat_message, content: "first", created_at: 1.hour.ago)
      new_message = create(:chat_message, content: "second", created_at: Time.current)

      expect(ChatMessage.chronological.to_a).to eq([ old_message, new_message ])
    end
  end
end
