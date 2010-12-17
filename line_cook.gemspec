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
  s.require_path = 'lib'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title Line-Cook}
  
  # add dependencies
  #s.add_dependency('json', '~> 1.4')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
    doc/Setup\ a\ VM
  }
  
  # list the files you want to include here.
  s.files = %W{
    lib/line_cook.rb
    lib/line_cook/attributes.rb
    lib/line_cook/generators/cookbook.rb
    lib/line_cook/generators/helpers.rb
    lib/line_cook/generators/script.rb
    lib/line_cook/helpers/bash.rb
    lib/line_cook/patches/templater.rb
    lib/line_cook/recipe.rb
    lib/line_cook/utils.rb
    lib/line_cook/version.rb
    tap.yml
    templates/line_cook/generators/cookbook/Tapfile
    templates/line_cook/generators/cookbook/_gitignore
    templates/line_cook/generators/cookbook/attributes/project_name.rb
    templates/line_cook/generators/cookbook/helpers/project_name/echo_args.erb
    templates/line_cook/generators/cookbook/helpers/project_name/reverse_echo_args.rb
    templates/line_cook/generators/cookbook/recipes/line_cook.rb
    templates/line_cook/generators/cookbook/recipes/project_name.rb
    templates/line_cook/generators/cookbook/vbox/setup/virtual_box
    templates/line_cook/generators/cookbook/vbox/ssh/id_rsa
    templates/line_cook/generators/cookbook/vbox/ssh/id_rsa.pub
    templates/line_cook/generators/helpers/_erb.erb
    templates/line_cook/generators/helpers/_rb.erb
    templates/line_cook/generators/helpers/helpers.erb
  }
end