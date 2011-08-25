require 'bundler/gem_tasks'
require 'bundler/setup'

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
    next if file =~ /^(rdoc|pkg|coverage|design|helpers|config|test)/ || File.directory?(file)
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
# VM Tasks
#

desc "start each vm at CURRENT"
task :start do
  sh 'linecook start --master-socket --snapshot CURRENT'
end

desc "snapshot each vm to a new CURRENT"
task :snapshot do
  sh 'linecook snapshot CURRENT'
end

desc "reset each vm to BASE"
task :reset_base do
  sh 'linecook snapshot --reset BASE'
  sh 'linecook snapshot CURRENT'
  sh 'linecook start --master-socket --snapshot CURRENT'
end

desc "stop each vm"
task :stop do
  sh 'linecook stop'
end

#
# Test tasks
#

def current_ruby
  `ruby -v`.split[0,2].join('-')
end

desc "Build helpers"
task :helpers do
  sh "linecook compile -L helpers -f"
end

desc 'Run the tests assuming the vm is running'
task :quicktest do
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

desc 'Run the tests vs each vm in config/ssh'
task :multitest do
  require 'thread'

  puts "Using: #{current_ruby}"

  hosts = `linecook state --hosts`.split("\n")
  hosts.collect! {|line| line.split(':').at(0) }

  log_dir = File.expand_path("../log/#{current_ruby}", __FILE__)
  unless File.exists?(log_dir)
    FileUtils.mkdir_p(log_dir)
  end

  threads = hosts.collect do |host|
    Thread.new do
      logfile = File.join(log_dir, host)
      Thread.current["host"] = host
      Thread.current["logfile"] = logfile

      cmd = "rake quicktest LINECOOK_TEST_HOST=#{host} > '#{logfile}' 2>&1"
      puts  "Multitest Host: #{host}"
      system(cmd)

      stdout  = File.read(logfile).split("\n")
      time    = stdout.grep(/^Finished in/)
      results = stdout.grep(/^\d+ tests/)
      puts "Using Host: #{host}\n  #{time}\n  #{results}"
    end
  end

  threads.each do |thread|
    thread.join
  end
end

desc 'Run the tests'
task :test do
  begin
    Rake::Task["start"].invoke
    Rake::Task["multitest"].invoke
  ensure
    Rake::Task["stop"].execute(nil)
  end
end

desc 'Run the cc tests'
task :cc => :test

desc 'Run rcov'
task :rcov do
  ENV['RCOV'] = 'true'
  Rake::Task['test'].invoke
end