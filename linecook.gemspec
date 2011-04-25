$:.unshift File.expand_path('../lib', __FILE__)
require 'linecook/version'
$:.shift

Gem::Specification.new do |s|
  s.name = 'linecook'
  s.version = Linecook::VERSION
  s.author  = 'Simon Chiang'
  s.email   = 'simon.a.chiang@gmail.com'
  s.summary = 'A shell script generator.'
  s.description = %w{
  Linecook generates shell scripts using an extensible set of ERB helpers. The
  shell scripts and associated resources (files, subscripts, etc) make up
  packages that can be used, for example, to provision servers.
  }.join(' ')
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
  s.add_dependency('bundler', '~> 1.0.7')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
    License.txt
    Tutorial/0\ -\ Intro
    Tutorial/1\ -\ VM\ Setup
    Tutorial/2\ -\ VM\ Control
    Tutorial/3\ -\ Running\ Scripts
    Tutorial/4\ -\ Generating\ Scripts
    Tutorial/5\ -\ Testing
  }
  
  # list the files you want to include here.
  s.files = %W{
    bin/linecook_run
    bin/linecook_scp
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
    lib/linecook/commands/run.rb
    lib/linecook/commands/snapshot.rb
    lib/linecook/commands/ssh.rb
    lib/linecook/commands/start.rb
    lib/linecook/commands/state.rb
    lib/linecook/commands/stop.rb
    lib/linecook/commands/vbox_command.rb
    lib/linecook/cookbook.rb
    lib/linecook/package.rb
    lib/linecook/proxy.rb
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
    templates/Rakefile
    templates/_gitignore
    templates/attributes/project_name.rb
    templates/config/ssh
    templates/cookbook
    templates/files/help.txt
    templates/helpers/project_name/assert_content_equal.erb
    templates/helpers/project_name/create_dir.erb
    templates/helpers/project_name/create_file.erb
    templates/helpers/project_name/install_file.erb
    templates/packages/abox.yml
    templates/project_name.gemspec
    templates/recipes/abox.rb
    templates/recipes/abox_test.rb
    templates/templates/todo.txt.erb
    templates/test/project_name_test.rb
    templates/test/test_helper.rb
  }
end