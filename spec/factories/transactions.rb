FactoryBot.define do
  factory :transaction do
    date { Date.current }
    description { "Test Transaction" }
    amount { -10.50 }
    account { "test-account" }
    transaction_id { SecureRandom.hex(8) }
    source { "emma_export" }
    category { nil }
    transaction_type { "DEB" }
    sort_code { "12-34-56" }
    account_number { "12345678" }
    balance { 1000.00 }
    bank { nil }
    currency { nil }
    subcategory { nil }
    tags { nil }
    counterparty { nil }
    merchant { nil }
    custom_name { nil }
    additional_details { nil }
    linked_transaction_id { nil }
    account_name { nil }
    emma_category { nil }

    trait :income do
      amount { 100.00 }
      transaction_type { "FPI" }
    end

    trait :expense do
      amount { -50.00 }
      transaction_type { "DEB" }
    end
  end
end
