require 'yard'
require_relative 'tasks/generate_snake_case'

task :default => [:generate_snake_case, :doc, :test_suite_reminder]

AMXLibVolume::Rake::GenerateSnakeCase.new

# Generate documentation.
YARD::Rake::YardocTask.new :doc do |t|
  t.options = %w(- license.txt)
end

task :test_suite_reminder do
  puts ''
  puts '-------------------------------'
  puts 'Remember to run the TEST SUITE!'
  puts '-------------------------------'
end