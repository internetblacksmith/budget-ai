FactoryBot.define do
  factory :chat_message do
    role { "user" }
    content { "What did I spend on food?" }

    trait :assistant do
      role { "assistant" }
      content { "Based on your transactions, you spent £150 on food this month." }
    end
  end
end
