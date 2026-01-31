FactoryBot.define do
  factory :transaction_edit do
    transaction_id { SecureRandom.hex(8) }
    source { "emma_export" }
    category { nil }
    is_transfer { nil }
    notes { nil }
    description { nil }
  end
end
