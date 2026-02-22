#!/usr/bin/env ruby

# Script to fix all MD3 migration issues comprehensively

def fix_file(file_path)
  content = File.read(file_path)
  original_content = content.dup

  # Fix duplicated class names in HTML attributes
  content.gsub!(/class="([^"]*?)md3-md3-([^"]*?)"/) do |match|
    classes = match[7..-2] # Remove class=" and "
    # Remove duplicated md3- prefixes
    fixed_classes = classes.gsub(/md3-md3-/, 'md3-')
    # Remove completely duplicated class names
    class_array = fixed_classes.split(/\s+/)
    unique_classes = class_array.uniq.join(' ')
    "class=\"#{unique_classes}\""
  end

  # Fix JavaScript variable names that got replaced incorrectly
  content.gsub!(/const md3-card md3-card-elevated/, 'const card')
  content.gsub!(/let md3-card md3-card-elevated/, 'let card')
  content.gsub!(/var md3-card md3-card-elevated/, 'var card')

  # Fix JavaScript references where variables were incorrectly replaced
  content.gsub!(/md3-card md3-card-elevated\.querySelector/, 'card.querySelector')
  content.gsub!(/md3-card md3-card-elevated\.classList/, 'card.classList')
  content.gsub!(/md3-card md3-card-elevated\.style/, 'card.style')

  # Fix CSS selectors where class names got broken
  content.gsub!(/\.(\w+)-md3-card md3-card-elevated/, '.\1-card')
  content.gsub!(/\.md-summary-md3-card md3-card-elevated/, '.md-summary-card')
  content.gsub!(/\.privacy-md3-card md3-card-elevated/, '.privacy-card')

  # Fix CSS selectors missing dots between classes
  content.gsub!(/\.(\w+-card) (md3-\w+)/, '.\1 .\2')
  content.gsub!(/\.(\w+-\w+) (md3-\w+)/, '.\1 .\2')

  # Fix invalid HTML tags that were created
  content.gsub!(/<md3-display-large>/, '<h1 class="md3-display-large">')
  content.gsub!(/<\/md3-display-large>/, '</h1>')
  content.gsub!(/<md3-display-medium>/, '<h2 class="md3-display-medium">')
  content.gsub!(/<\/md3-display-medium>/, '</h2>')
  content.gsub!(/<md3-display-small>/, '<h3 class="md3-display-small">')
  content.gsub!(/<\/md3-display-small>/, '</h3>')
  content.gsub!(/<md3-headline-large>/, '<h2 class="md3-headline-large">')
  content.gsub!(/<\/md3-headline-large>/, '</h2>')
  content.gsub!(/<md3-headline-medium>/, '<h3 class="md3-headline-medium">')
  content.gsub!(/<\/md3-headline-medium>/, '</h3>')
  content.gsub!(/<md3-headline-small>/, '<h4 class="md3-headline-small">')
  content.gsub!(/<\/md3-headline-small>/, '</h4>')

  # Fix lone dots in CSS (from broken class replacements)
  content.gsub!(/^\.$/, '.md3-button')
  content.gsub!(/^\.[\s\{]/, '.md3-button {')

  # Fix specific component references
  content.gsub!(/md3-card md3-card-elevated/, 'md3-card md3-card-elevated')
  content.gsub!(/privacy-md3-md3-card md3-card-elevated/, 'privacy-card')

  # Only write if changes were made
  if content != original_content
    File.write(file_path, content)
    puts "Fixed: #{file_path}"
    true
  else
    false
  end
end

# Get all files to fix
base_dir = File.expand_path("../..", __dir__)
view_files = Dir.glob(File.join(base_dir, "app/views/**/*.html.erb"))
js_files = Dir.glob(File.join(base_dir, "app/javascript/**/*.js"))
css_files = Dir.glob(File.join(base_dir, "app/assets/stylesheets/*.css"))

all_files = view_files + js_files + css_files

puts "Checking #{all_files.length} files for MD3 issues..."

fixed_count = 0
all_files.each do |file|
  fixed_count += 1 if fix_file(file)
end

puts "\nFixed #{fixed_count} files"
puts "MD3 migration cleanup complete!"
