require 'bundler/gem_tasks'

#
# Gem specification
#

def gemspec
  @gemspec ||= eval(File.read('linecook.gemspec'), TOPLEVEL_BINDING)
end

desc 'Prints the gemspec manifest.'
task :manifest do
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
    next if File.extname(file) == '.rbc'
    
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
task :rdoc do
  spec  = gemspec
  files =  spec.files.select {|file| File.extname(file) == '.rb' }
  files += spec.extra_rdoc_files
  options = spec.rdoc_options.join(' ')
  
  Dir.chdir File.expand_path('..', __FILE__) do
    FileUtils.rm_r 'rdoc'
    sh "rdoc -o rdoc #{options} '#{files.join("' '")}'"
  end
end

#
# Dependency tasks
#

desc 'Bundle dependencies'
task :bundle do
  output = `bundle check 2>&1`
  
  unless $?.to_i == 0
    puts output
    sh "bundle install 2>&1"
    puts
  end
end

#
# Test tasks
#

def current_ruby
  `ruby -v`.split[0,2].join('-')
end

desc 'Run the tests'
task :test => :bundle do
  tests = Dir.glob('test/**/*_test.rb')
  tests.delete_if {|test| test =~ /_test\/test_/ }
  
  puts "Using #{current_ruby}"
  if ENV['RCOV'] == 'true'
    FileUtils.rm_rf File.expand_path('../coverage', __FILE__)
    sh('rcov', '-w', '--text-report', '--exclude', '^/', *tests)
  else
    sh('ruby', '-w', '-e', 'ARGV.dup.each {|test| load test}', *tests)
  end
end

desc 'Run the cc tests'
task :cc => :test

desc 'Run rcov'
task :rcov do
  ENV['RCOV'] = 'true'
  Rake::Task['test'].invoke
end