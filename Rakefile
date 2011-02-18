require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'

#
# Gem specification
#

def gemspec
  @gemspec ||= eval(File.read('linecook.gemspec'), TOPLEVEL_BINDING)
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end

desc 'Prints the gemspec manifest.'
task :print_manifest do
  # collect files from the gemspec, labeling 
  # with true or false corresponding to the
  # file existing or not
  files = gemspec.files.inject({}) do |files, file|
    files[File.expand_path(file)] = [File.exists?(file), file]
    files
  end
  
  # gather non-rdoc/pkg files for the project
  # and add to the files list if they are not
  # included already (marking by the absence
  # of a label)
  Dir.glob('**/*').each do |file|
    next if file =~ /^(rdoc|pkg|coverage|scripts|design|demo|helpers|config|test|vendor|vm)/ || File.directory?(file)
    
    path = File.expand_path(file)
    files[path] = ['', file] unless files.has_key?(path)
  end
  
  # sort and output the results
  files.values.sort_by {|exists, file| file }.each do |entry| 
    puts '%-5s %s' % entry
  end
end

#
# Documentation tasks
#

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  spec = gemspec
  
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options.concat(spec.rdoc_options)
  rdoc.rdoc_files.include( spec.extra_rdoc_files )
  
  files = spec.files.select {|file| file =~ /^lib.*\.rb$/}
  rdoc.rdoc_files.include( files )
end

#
# Dependency tasks
#

# Xpromote raises an error if it finds output on stderr. Unfortunately the sh
# from Rake will print the cmd on stderr, so use this method instead for
# commands that run during promotion.
def stdout_sh(cmd)
  puts cmd
  system(cmd) or raise("command failed: #{cmd}")
end

desc 'Checkout submodules'
task :submodules do
  output = `git submodule status 2>&1`
  
  if output =~ /^-/m
    puts "Missing submodules:\n#{output}"
    stdout_sh "git submodule init"
    stdout_sh "git submodule update"
    puts
  end
end

desc 'Bundle dependencies'
task :bundle => :submodules do
  opts = %w{prd acp qa tst}.include?(ENV['WCIS_ENV']) ? ' --without=development' : ''
  output = `bundle check 2>&1`
  
  unless $?.to_i == 0
    puts output
    stdout_sh "bundle install#{opts} 2>&1"
    puts
  end
end

#
# VM Tasks
#

namespace :vm do
  desc "start each vm at CURRENT and share vm directory"
  task :start => :bundle do
    sh 'bundle exec linecook start --socket --snapshot CURRENT'
    sh 'bundle exec linecook share'
  end
  
  desc "snapshot each vm to a new CURRENT"
  task :snapshot => :bundle do
    sh 'bundle exec linecook snapshot CURRENT'
  end
  
  desc "reset each vm to BASE and share vm directory"
  task :reset => :bundle do
    sh 'bundle exec linecook start --socket --snapshot BASE'
    sh 'bundle exec linecook share'
  end
  
  desc "stop each vm"
  task :stop => :bundle do
    sh 'bundle exec linecook stop'
  end
end

#
# Test tasks
#

desc 'Default: Run tests.'
task :default => :test

desc 'Run the tests assuming the vm is running'
task :quicktest => :bundle do
  tests = Dir.glob('test/**/*_test.rb')
  tests.delete_if {|test| test =~ /_test\/test_/ }
  
  if ENV['RCOV'] == 'true'
    FileUtils.rm_rf File.expand_path('../coverage', __FILE__)
    sh('rcov', '-w', '--text-report', '--exclude', '^/', *tests)
  else
    sh('ruby', '-w', '-e', 'ARGV.dup.each {|test| load test}', *tests)
  end
end

desc 'Run the tests'
task :test do
  begin
    Rake::Task["vm:start"].invoke
    Rake::Task["quicktest"].invoke
  ensure
    Rake::Task["vm:stop"].execute(nil)
  end
end

desc 'Run the cc tests'
task :cc => :test

desc 'Run rcov'
task :rcov do
  ENV['RCOV'] = 'true'
  Rake::Task["test"].invoke
end
