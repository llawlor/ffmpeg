require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "ffmpeg"
    s.summary = %Q{A dsl for building and executing ffmpeg commands}
    s.email = "lee@leehorrocks.com"
    s.homepage = "http://github.com/leeh/ffmpeg"
    s.description = "A dsl for building and executing ffmpeg commands"
    s.authors = ["Patrik Hedman", "Lee Horrocks"]
  end
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
# 
# require 'rdoc'
# require 'rdoc/rdoc'
# 
# options = RDoc::Options.new
# # see RDoc::Options
# 
# rdoc = RDoc::RDoc.new
# rdoc.document options
# # see RDoc::RDoc

# 
# Rake::RDocTask.new do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = 'ffmpeg'
#   rdoc.options << '--line-numbers' << '--inline-source'
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  puts "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
end

task :default => :spec
