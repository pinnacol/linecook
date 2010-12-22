$:.unshift File.expand_path('../lib', __FILE__)
require 'linecook/version'
$:.shift

Gem::Specification.new do |s|
  s.name = 'linecook'
  s.version = Linecook::VERSION
  s.author  = 'Simon Chiang'
  s.email   = 'simon.chiang@pinnacol.com'
  s.summary = 'A shell script generator.'
  s.homepage = 'http://gems.pinnacol.com/linecook'
  s.rubyforge_project = ''
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title Linecook}
  
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables = 'linecook'
  
  # add dependencies
  s.add_dependency('rake', '~> 0.8.7')
  s.add_dependency('linebook', '~> 0.1.0')
  s.add_development_dependency('bundler', '~> 1.0.7')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
    License.txt
  }
  
  # list the files you want to include here.
  s.files = %W{
    bin/linecook
    lib/linecook.rb
    lib/linecook/attributes.rb
    lib/linecook/cookbook.rb
    lib/linecook/helper.rb
    lib/linecook/recipe.rb
    lib/linecook/script.rb
    lib/linecook/template.rb
    lib/linecook/test_helper.rb
    lib/linecook/utils.rb
    lib/linecook/version.rb
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