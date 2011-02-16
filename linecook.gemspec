$:.unshift File.expand_path('../lib', __FILE__)
require 'linecook/version'
$:.shift

Gem::Specification.new do |s|
  s.name = 'linecook'
  s.version = Linecook::VERSION
  s.author  = 'Simon Chiang'
  s.email   = 'simon.chiang@pinnacol.com'
  s.summary = 'A shell script generator.'
  s.homepage = Linecook::WEBSITE
  s.rubyforge_project = ''
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title Linecook}
  
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables = 'linecook'
  
  # add dependencies
  s.add_dependency('rake', '~> 0.8.7')
  s.add_dependency('configurable', '~> 0.7.0')
  s.add_development_dependency('bundler', '~> 1.0.7')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
    License.txt
  }
  
  # list the files you want to include here.
  s.files = %W{
    bin/linecook_test
    lib/linecook.rb
    lib/linecook/attributes.rb
    lib/linecook/commands.rb
    lib/linecook/commands/build.rb
    lib/linecook/commands/command.rb
    lib/linecook/commands/command_error.rb
    lib/linecook/commands/env.rb
    lib/linecook/commands/helper.rb
    lib/linecook/commands/init.rb
    lib/linecook/commands/package.rb
    lib/linecook/commands/preview.rb
    lib/linecook/commands/share.rb
    lib/linecook/commands/snapshot.rb
    lib/linecook/commands/ssh.rb
    lib/linecook/commands/start.rb
    lib/linecook/commands/state.rb
    lib/linecook/commands/stop.rb
    lib/linecook/commands/test.rb
    lib/linecook/commands/vbox_command.rb
    lib/linecook/cookbook.rb
    lib/linecook/package.rb
    lib/linecook/recipe.rb
    lib/linecook/template.rb
    lib/linecook/test.rb
    lib/linecook/test/command_parser.rb
    lib/linecook/test/file_test.rb
    lib/linecook/test/regexp_escape.rb
    lib/linecook/test/shell_test.rb
    lib/linecook/utils.rb
    lib/linecook/version.rb
    templates/Gemfile
    templates/README
    templates/Rakefile
    templates/_gitignore
    templates/attributes/project_name.rb
    templates/config/ssh
    templates/cookbook
    templates/files/file.txt
    templates/helpers/project_name/cat.erb
    templates/helpers/project_name/echo.erb
    templates/packages/abox.yml
    templates/project_name.gemspec
    templates/recipes/project_name.rb
    templates/recipes/project_name_test.rb
    templates/templates/template.txt.erb
    templates/test/project_name_test.rb
    templates/test/test_helper.rb
    templates/vm/ssh/id_rsa
    templates/vm/ssh/id_rsa.pub
  }
end