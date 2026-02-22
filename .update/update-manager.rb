#!/usr/bin/env ruby
# Simple update manager for Budget AI

require 'json'
require 'fileutils'
require 'open-uri'

class UpdateManager
  VERSION_FILE = 'VERSION'
  UPDATE_INFO_FILE = '.update/update-info.json'
  BACKUP_DIR = 'backups'
  
  def initialize
    @current_version = File.read(VERSION_FILE).strip rescue "0.0.0"
  end
  
  def check_for_updates
    # In a real system, this would check a remote server
    # For now, we'll check a local update info file
    return unless File.exist?(UPDATE_INFO_FILE)
    
    update_info = JSON.parse(File.read(UPDATE_INFO_FILE))
    latest_version = update_info['latest_version']
    
    if version_newer?(latest_version, @current_version)
      {
        available: true,
        current_version: @current_version,
        latest_version: latest_version,
        changes: update_info['changes'],
        release_date: update_info['release_date']
      }
    else
      { available: false, current_version: @current_version }
    end
  rescue => e
    puts "Error checking for updates: #{e.message}"
    { available: false, error: e.message }
  end
  
  def create_backup
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_path = File.join(BACKUP_DIR, "backup_#{timestamp}")
    
    FileUtils.mkdir_p(backup_path)
    
    # Backup database files
    Dir.glob("storage/*.sqlite3").each do |file|
      FileUtils.cp(file, backup_path)
    end
    
    # Backup environment files
    Dir.glob(".env*").each do |file|
      FileUtils.cp(file, backup_path) if File.file?(file)
    end
    
    puts "Backup created at: #{backup_path}"
    backup_path
  end
  
  private
  
  def version_newer?(version1, version2)
    v1_parts = version1.split('.').map(&:to_i)
    v2_parts = version2.split('.').map(&:to_i)
    
    v1_parts.zip(v2_parts).each do |v1, v2|
      return true if (v1 || 0) > (v2 || 0)
      return false if (v1 || 0) < (v2 || 0)
    end
    
    false
  end
end

# Run if called directly
if __FILE__ == $0
  manager = UpdateManager.new
  update_info = manager.check_for_updates
  
  if update_info[:available]
    puts "Update available!"
    puts "Current version: #{update_info[:current_version]}"
    puts "Latest version: #{update_info[:latest_version]}"
    puts "\nChanges:"
    update_info[:changes].each { |change| puts "  - #{change}" }
  else
    puts "You're running the latest version (#{update_info[:current_version]})"
  end
end