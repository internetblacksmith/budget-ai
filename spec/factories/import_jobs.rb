FactoryBot.define do
  factory :import_job do
    filename { "test_import.csv" }
    status { "pending" }
    source { "emma_export" }
    total_files { 1 }
    processed_files { 0 }
    imported_count { 0 }
    error_messages { [] }

    trait :processing do
      status { "processing" }
      started_at { Time.current }
      processed_files { 1 }
    end

    trait :completed do
      status { "completed" }
      started_at { 1.minute.ago }
      completed_at { Time.current }
      processed_files { total_files }
      imported_count { 10 }
    end

    trait :failed do
      status { "failed" }
      started_at { 1.minute.ago }
      completed_at { Time.current }
      error_messages { [ "Import failed: Invalid CSV format" ] }
    end
  end
end
