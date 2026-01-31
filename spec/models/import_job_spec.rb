require 'rails_helper'

RSpec.describe ImportJob, type: :model do
  describe 'validations' do
    it 'validates inclusion of status' do
      job = ImportJob.new(source: 'emma_export', total_files: 1)
      job.status = 'invalid_status'
      expect(job).not_to be_valid
    end

    it 'validates inclusion of source' do
      job = ImportJob.new(total_files: 1)
      job.source = 'invalid_source'
      expect(job).not_to be_valid
    end

    it 'requires valid total_files' do
      job = ImportJob.new(source: 'emma_export', total_files: -1)
      expect(job).not_to be_valid
    end
  end

  describe '#display_status' do
    let(:import_job) { ImportJob.new(source: 'emma_export') }

    it 'shows success message for completed imports' do
      import_job.status = 'completed'
      import_job.imported_count = 25
      expect(import_job.display_status).to eq("Successfully imported 25 transactions")
    end

    it 'shows no transactions message when none imported' do
      import_job.status = 'completed'
      import_job.imported_count = 0
      expect(import_job.display_status).to eq("Import completed with no new transactions")
    end

    it 'shows error message for failed imports' do
      import_job.status = 'failed'
      import_job.error_messages = [ "File not found" ]
      expect(import_job.display_status).to eq("Import failed: File not found")
    end

    it 'shows progress for processing imports' do
      import_job.status = 'processing'
      expect(import_job.display_status).to eq("Processing...")
    end

    it 'shows pending status' do
      import_job.status = 'pending'
      expect(import_job.display_status).to eq("Waiting to start...")
    end
  end

  describe 'scopes' do
    before do
      ImportJob.create!(status: 'pending', source: 'emma_export', total_files: 1)
      ImportJob.create!(status: 'processing', source: 'emma_export', total_files: 1, created_at: 1.hour.ago)
      ImportJob.create!(status: 'completed', source: 'emma_export', total_files: 1, updated_at: 5.minutes.ago)
      ImportJob.create!(status: 'failed', source: 'emma_export', total_files: 1, updated_at: 20.minutes.ago)
    end

    it 'returns active jobs' do
      active_jobs = ImportJob.active
      expect(active_jobs.count).to eq(2)
      expect(active_jobs.map(&:status)).to contain_exactly('pending', 'processing')
    end

    it 'returns recent jobs in correct order' do
      recent_jobs = ImportJob.recent
      expect(recent_jobs.count).to eq(4)
      expect(recent_jobs.first.created_at).to be >= recent_jobs.last.created_at
    end

    it 'returns recently completed jobs' do
      completed_recently = ImportJob.completed_recently
      expect(completed_recently.count).to eq(1)
      expect(completed_recently.first.status).to eq('completed')
    end
  end
end
