#!/usr/bin/env ruby
# frozen_string_literal: true

# Coverage Enforcement Script
# Runs after tests to ensure coverage thresholds are met
# Usage: ruby scripts/check_coverage.rb [--strict]
#
# Exit codes:
#   0 - All coverage thresholds met
#   1 - Coverage below minimum threshold
#   2 - Critical files below required coverage

require "json"

COVERAGE_FILE = "coverage/.last_run.json"
RESULTSET_FILE = "coverage/.resultset.json"

# Minimum overall coverage required
MINIMUM_COVERAGE = 80.0

# Critical files that require higher coverage
CRITICAL_FILES = {
  "controllers/google_auth_controller.rb" => 75,
  "models/transaction.rb" => 80,
  "models/import_job.rb" => 80,
  "services/emma_spreadsheet_import_service.rb" => 80,
  "jobs/emma_spreadsheet_import_job.rb" => 80
}.freeze

# Files that are allowed to have lower coverage (test utilities, etc.)
EXCLUDED_FILES = [
  "controllers/test_sessions_controller.rb",
  "services/llm_client.rb" # External API, hard to test
].freeze

def load_coverage_data
  unless File.exist?(COVERAGE_FILE)
    puts "❌ Coverage file not found: #{COVERAGE_FILE}"
    puts "   Run tests first: bundle exec rspec"
    exit 1
  end

  JSON.parse(File.read(COVERAGE_FILE))
end

def load_detailed_coverage
  return {} unless File.exist?(RESULTSET_FILE)

  data = JSON.parse(File.read(RESULTSET_FILE))
  rspec_data = data["RSpec"] || data.values.first
  rspec_data["coverage"] || {}
end

def calculate_file_coverage(lines)
  return 0 if lines.nil?

  lines = lines["lines"] if lines.is_a?(Hash)
  return 0 if lines.nil?

  total = lines.compact.count
  return 0 if total.zero?

  covered = lines.compact.count { |l| l.positive? }
  (covered.to_f / total * 100).round(1)
end

def check_overall_coverage(data)
  coverage = data.dig("result", "line") || 0

  if coverage < MINIMUM_COVERAGE
    puts "❌ Overall coverage #{coverage}% is below minimum #{MINIMUM_COVERAGE}%"
    return false
  end

  puts "✅ Overall coverage: #{coverage}%"
  true
end

def check_critical_files(detailed_coverage)
  failures = []

  CRITICAL_FILES.each do |file_pattern, required_coverage|
    matching_file = detailed_coverage.keys.find { |f| f.include?(file_pattern) }

    if matching_file
      coverage = calculate_file_coverage(detailed_coverage[matching_file])

      if coverage < required_coverage
        failures << { file: file_pattern, coverage: coverage, required: required_coverage }
        puts "❌ #{file_pattern}: #{coverage}% (required: #{required_coverage}%)"
      else
        puts "✅ #{file_pattern}: #{coverage}%"
      end
    else
      puts "⚠️  #{file_pattern}: not found in coverage data"
    end
  end

  failures.empty?
end

def check_low_coverage_files(detailed_coverage)
  puts "\n📊 Files with coverage below 80%:"

  low_coverage_files = []

  detailed_coverage.each do |file, lines|
    next unless file.include?("/app/")

    short_file = file.split("/app/").last
    next if EXCLUDED_FILES.any? { |excluded| short_file.include?(excluded) }

    coverage = calculate_file_coverage(lines)
    next if coverage >= 80

    low_coverage_files << { file: short_file, coverage: coverage }
  end

  if low_coverage_files.empty?
    puts "   All files meet 80% coverage threshold!"
  else
    low_coverage_files.sort_by { |f| f[:coverage] }.each do |file_data|
      puts "   #{file_data[:coverage]}% - #{file_data[:file]}"
    end
  end

  low_coverage_files
end

def main
  strict_mode = ARGV.include?("--strict")

  puts "🔍 Coverage Check #{strict_mode ? '(strict mode)' : ''}"
  puts "=" * 50

  data = load_coverage_data
  detailed = load_detailed_coverage

  overall_ok = check_overall_coverage(data)

  puts "\n📋 Critical Files Coverage:"
  critical_ok = check_critical_files(detailed)

  low_coverage = check_low_coverage_files(detailed)

  puts "\n" + "=" * 50

  if !overall_ok
    puts "❌ FAILED: Overall coverage below threshold"
    exit 1
  elsif !critical_ok
    puts "❌ FAILED: Critical files below required coverage"
    exit 2
  elsif strict_mode && low_coverage.any?
    puts "❌ FAILED (strict): #{low_coverage.count} files below 80%"
    exit 1
  else
    puts "✅ PASSED: All coverage requirements met"
    exit 0
  end
end

main
