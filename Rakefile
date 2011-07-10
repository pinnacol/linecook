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
