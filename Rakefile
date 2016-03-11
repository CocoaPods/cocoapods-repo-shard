require 'bundler/gem_tasks'

begin
  require 'bundler/setup'

  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'

  RSpec::Core::RakeTask.new
  RuboCop::RakeTask.new

  task default: [:rubocop, :spec]
rescue LoadError
  puts '[!] Some tasks have been disabled due to missing dependencies. ' \
       'Run `bundle install`.'
end
