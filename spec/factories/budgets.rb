FactoryBot.define do
  factory :budget do
    category { "Groceries" }
    monthly_limit { 200.00 }
    notes { nil }

    trait :with_notes do
      notes { "Weekly shop budget" }
    end
  end
end
