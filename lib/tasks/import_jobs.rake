namespace :import_jobs do
  desc "Clean up orphaned/stuck import jobs"
  task cleanup: :environment do
    puts "🔍 Checking for orphaned import jobs..."

    count = ImportJob.cleanup_orphaned_jobs!

    if count > 0
      puts "✅ Cleaned up #{count} orphaned import job(s)"
    else
      puts "✨ No orphaned import jobs found"
    end
  end

  desc "Show current import job status"
  task status: :environment do
    puts "\n📊 Current Import Job Status:"
    puts "=" * 40

    ImportJob.group(:status, :source).count.each do |(status, source), count|
      puts "#{source.capitalize} - #{status.capitalize}: #{count}"
    end

    active_jobs = ImportJob.active.count
    if active_jobs > 0
      puts "\n⚠️  Warning: #{active_jobs} job(s) currently active"
      puts "   If no imports are actually running, use: rake import_jobs:cleanup"
    end

    puts "\n📈 Recent Activity (last 24 hours):"
    recent = ImportJob.where(created_at: 24.hours.ago..).order(created_at: :desc).limit(5)

    if recent.any?
      recent.each do |job|
        status_emoji = case job.status
        when "completed" then "✅"
        when "failed" then "❌"
        when "processing" then "⏳"
        when "pending" then "⏸️"
        else "❓"
        end

        puts "  #{status_emoji} #{job.source.capitalize} - #{job.status} (#{time_ago_in_words(job.created_at)} ago)"
      end
    else
      puts "  No recent import activity"
    end

    puts ""
  end

  desc "Force fail all active import jobs (emergency use only)"
  task emergency_stop: :environment do
    puts "🚨 EMERGENCY: Stopping all active import jobs..."

    active_jobs = ImportJob.active
    count = active_jobs.count

    if count == 0
      puts "✨ No active jobs to stop"
      exit
    end

    puts "⚠️  This will mark #{count} job(s) as failed!"
    print "Are you sure? (y/N): "

    confirmation = STDIN.gets.chomp.downcase
    unless confirmation == "y" || confirmation == "yes"
      puts "❌ Operation cancelled"
      exit
    end

    active_jobs.find_each do |job|
      job.mark_as_failed("Manually stopped via emergency_stop rake task")
      puts "🛑 Stopped job ##{job.id} (#{job.source})"
    end

    puts "✅ Emergency stop completed for #{count} job(s)"
  end

  private

  def time_ago_in_words(time)
    # Simple time ago implementation for rake tasks
    seconds = Time.current - time
    case seconds
    when 0..59
      "#{seconds.to_i} seconds"
    when 60..3599
      "#{(seconds / 60).to_i} minutes"
    when 3600..86399
      "#{(seconds / 3600).to_i} hours"
    else
      "#{(seconds / 86400).to_i} days"
    end
  end
end
