$:.unshift File.expand_path('../lib', __FILE__)
require 'line_cook/version'
$:.shift

Gem::Specification.new do |s|
  s.name = 'line_cook'
  s.version = LineCook::VERSION
  s.author  = 'Simon Chiang'
  s.email   = 'simon.chiang@pinnacol.com'
  s.summary = 'A shell script generator.'
  s.homepage = 'http://gems.pinnacol.com/line_cook'
  s.rubyforge_project = ''
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title LineCook}
  
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables = 'line_cook'
  
  # add dependencies
  s.add_dependency('rake', '~> 0.8.7')
  s.add_development_dependency('bundler', '~> 1.0.7')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
  }
  
  # list the files you want to include here.
  s.files = %W{
    bin/line_cook
    lib/line_cook.rb
    lib/line_cook/attributes.rb
    lib/line_cook/cookbook.rb
    lib/line_cook/helper.rb
    lib/line_cook/recipe.rb
    lib/line_cook/script.rb
    lib/line_cook/template.rb
    lib/line_cook/test_helper.rb
    lib/line_cook/utils.rb
    lib/line_cook/version.rb
    templates/Cookbook
    templates/README
    templates/Rakefile
    templates/_gitignore
    templates/attributes/project_name.rb
    templates/helpers/project_name/echo.erb
    templates/recipes/project_name.rb
    templates/scripts/project_name.yml
    templates/vbox/setup/virtual_box
    templates/vbox/ssh/id_rsa
    templates/vbox/ssh/id_rsa.pub
  }
end