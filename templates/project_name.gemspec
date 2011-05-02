# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = '<%= project_name %>'
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'TODO: Write your name'
  s.email       = 'TODO: Write your email address'
  s.homepage    = ''
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}
  s.rubyforge_project = ''
  
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title <%= project_name.capitalize %>}
  
  # add dependencies
  s.add_dependency('linecook', '~> <%= Linecook::VERSION %>')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    cookbook
  }
  
  # list the files you want to include here.
  s.files = %W{
  }
  
  s.require_path = 'lib'
end
