namespace :import_jobs do
  desc "Clean up orphaned/stuck import jobs"
  task cleanup: :environment do
    puts "Checking for orphaned import jobs..."

    count = ImportJob.active.where(updated_at: ...30.minutes.ago).update_all(
      status: "failed",
      error_messages: '["Cleaned up: orphaned job"]'
    )

    if count > 0
      puts "Cleaned up #{count} orphaned import job(s)"
    else
      puts "No orphaned import jobs found"
    end
  end

  desc "Show current import job status"
  task status: :environment do
    puts "\nCurrent Import Job Status:"
    puts "=" * 40

    ImportJob.group(:status, :source).count.each do |(status, source), count|
      puts "#{source} - #{status}: #{count}"
    end

    active_jobs = ImportJob.active.count
    if active_jobs > 0
      puts "\nWarning: #{active_jobs} job(s) currently active"
      puts "   If no imports are actually running, use: rake import_jobs:cleanup"
    end

    puts "\nRecent Activity (last 24 hours):"
    recent = ImportJob.where(created_at: 24.hours.ago..).order(created_at: :desc).limit(5)

    if recent.any?
      recent.each do |job|
        elapsed = Time.current - job.created_at
        ago = if elapsed < 60 then "#{elapsed.to_i}s ago"
        elsif elapsed < 3600 then "#{(elapsed / 60).to_i}m ago"
        else "#{(elapsed / 3600).to_i}h ago"
        end
        puts "  [#{job.status}] #{job.source} (#{ago})"
      end
    else
      puts "  No recent import activity"
    end
  end

  desc "Force fail all active import jobs (emergency use only)"
  task emergency_stop: :environment do
    active_jobs = ImportJob.active
    count = active_jobs.count

    if count == 0
      puts "No active jobs to stop"
      exit
    end

    puts "This will mark #{count} job(s) as failed!"
    print "Are you sure? (y/N): "

    confirmation = $stdin.gets.chomp.downcase
    unless %w[y yes].include?(confirmation)
      puts "Operation cancelled"
      exit
    end

    active_jobs.update_all(
      status: "failed",
      error_messages: '["Manually stopped via emergency_stop rake task"]'
    )

    puts "Emergency stop completed for #{count} job(s)"
  end
end
