#!/usr/bin/env ruby

# Script to migrate from old Material Design classes to MD3
# This updates all view files to use the new Material Design 3 classes

require 'fileutils'

# Define class mappings
CLASS_MAPPINGS = {
  # Button mappings
  'btn btn-primary' => 'md3-button md3-button-filled',
  'btn btn-secondary' => 'md3-button md3-button-tonal',
  'btn btn-outline-primary' => 'md3-button md3-button-outlined',
  'btn btn-outline-secondary' => 'md3-button md3-button-outlined',
  'btn btn-danger' => 'md3-button md3-button-filled md3-error',
  'btn btn-success' => 'md3-button md3-button-filled md3-success',
  'btn btn-warning' => 'md3-button md3-button-filled md3-warning',
  'btn btn-link' => 'md3-button md3-button-text',
  'btn-lg' => 'md3-button-large',
  'btn-sm' => 'md3-button-small',

  # Old MD button mappings
  'md-button md-button-filled' => 'md3-button md3-button-filled',
  'md-button md-button-outlined' => 'md3-button md3-button-outlined',
  'md-button md-button-text' => 'md3-button md3-button-text',
  'md-button md-button-elevated' => 'md3-button md3-button-elevated',
  'md-icon-button' => 'md3-icon-button',

  # Card mappings
  'md-card' => 'md3-card md3-card-elevated',
  'card' => 'md3-card md3-card-elevated',
  'card-body' => 'md3-card-content',
  'card-title' => 'md3-card-title',
  'card-subtitle' => 'md3-card-subtitle',
  'card-text' => 'md3-card-supporting-text',

  # Typography mappings
  'h1' => 'md3-display-large',
  'h2' => 'md3-headline-large',
  'h3' => 'md3-headline-medium',
  'h4' => 'md3-headline-small',
  'h5' => 'md3-title-large',
  'h6' => 'md3-title-medium',

  # Form mappings
  'form-control' => 'md3-text-field-input',
  'form-label' => 'md3-text-field-label',
  'form-text' => 'md3-text-field-helper',
  'form-check-input' => 'md3-checkbox',
  'form-select' => 'md3-select',

  # Alert/notification mappings
  'alert alert-danger' => 'md3-snackbar md3-error',
  'alert alert-success' => 'md3-snackbar md3-success',
  'alert alert-warning' => 'md3-snackbar md3-warning',
  'alert alert-info' => 'md3-snackbar',

  # Color token mappings (for inline styles and CSS)
  '--md-primary' => '--md-sys-color-primary',
  '--md-secondary' => '--md-sys-color-secondary',
  '--md-surface' => '--md-sys-color-surface',
  '--md-surface-variant' => '--md-sys-color-surface-variant',
  '--md-on-surface' => '--md-sys-color-on-surface',
  '--md-on-surface-variant' => '--md-sys-color-on-surface-variant',
  '--md-error' => '--md-sys-color-error',
  '--md-success' => '--md-sys-color-success',
  '--md-warning' => '--md-sys-color-warning',
  '--md-background' => '--md-sys-color-background',
  '--md-on-background' => '--md-sys-color-on-background'
}

# Files to process
VIEW_PATTERNS = [
  'app/views/**/*.erb',
  'app/views/**/*.html',
  'app/assets/stylesheets/**/*.css',
  'app/assets/stylesheets/**/*.scss',
  'app/javascript/**/*.js'
]

def process_file(file_path)
  content = File.read(file_path)
  original_content = content.dup
  changes_made = false

  CLASS_MAPPINGS.each do |old_class, new_class|
    # Match class attributes
    if content.gsub!(/class="([^"]*)\b#{Regexp.escape(old_class)}\b([^"]*)"/) do |match|
        classes = $1 + new_class + $2
        changes_made = true
        "class=\"#{classes.strip.gsub(/\s+/, ' ')}\""
      end
    end

    # Match CSS variables
    if content.gsub!(/#{Regexp.escape(old_class)}/, new_class)
      changes_made = true
    end
  end

  if changes_made
    File.write(file_path, content)
    puts "✅ Updated: #{file_path}"
    true
  else
    false
  end
end

def main
  puts "🚀 Starting Material Design 3 migration..."
  puts "=" * 50

  total_files = 0
  updated_files = 0

  VIEW_PATTERNS.each do |pattern|
    Dir.glob(pattern).each do |file|
      next if File.directory?(file)
      total_files += 1

      if process_file(file)
        updated_files += 1
      end
    end
  end

  puts "=" * 50
  puts "✨ Migration complete!"
  puts "📊 Statistics:"
  puts "   Total files scanned: #{total_files}"
  puts "   Files updated: #{updated_files}"
  puts "   Files unchanged: #{total_files - updated_files}"

  if updated_files > 0
    puts "\n⚠️  Please review the changes and test your application!"
    puts "💡 Tip: Run 'git diff' to see all changes made"
  end
end

# Run the migration
main if __FILE__ == $0
