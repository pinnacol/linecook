# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'linecook/version'

Gem::Specification.new do |s|
  s.name        = 'linecook'
  s.version     = Linecook::VERSION
  s.authors     = ['Simon Chiang']
  s.email       = ['simon.a.chiang@gmail.com']
  s.homepage    = Linecook::WEBSITE
  s.summary     = 'A shell script generator.'
  s.description = %w{
  Linecook generates shell scripts using an extensible set of ERB helpers. The
  shell scripts and associated resources (files, subscripts, etc) make up
  packages that can be used, for example, to provision servers.
  }.join(' ')

  s.rubyforge_project = 'linecook'
  s.has_rdoc = true
  s.rdoc_options.concat %w{--main README.rdoc -S -N --title Linecook}
  s.extra_rdoc_files = %w{
    History.rdoc
    README.rdoc
    License.txt
    doc/vm_setup.rdoc
  }

  # add dependencies
  s.add_dependency('config_parser', '~> 0.5.5')
  s.add_dependency('configurable', '~> 1.0')
  s.add_dependency('tilt', '~> 1.3')
  s.add_development_dependency('rake', '~> 0.9.2')
  s.add_development_dependency('bundler', '~> 1.0')
  s.add_development_dependency('rcov', '~> 0.9')
  s.add_development_dependency('rdoc', '~> 3.9')
  s.add_development_dependency('shell_test', '~> 0.2.0')

  s.files         = %w{
    bin/linecook_run
    bin/linecook_scp
    lib/linecook.rb
    lib/linecook/attributes.rb
    lib/linecook/command.rb
    lib/linecook/command_set.rb
    lib/linecook/command_utils.rb
    lib/linecook/commands/build.rb
    lib/linecook/commands/compile.rb
    lib/linecook/commands/compile_helper.rb
    lib/linecook/commands/run.rb
    lib/linecook/commands/snapshot.rb
    lib/linecook/commands/ssh.rb
    lib/linecook/commands/start.rb
    lib/linecook/commands/state.rb
    lib/linecook/commands/stop.rb
    lib/linecook/commands/virtual_box_command.rb
    lib/linecook/cookbook.rb
    lib/linecook/executable.rb
    lib/linecook/os/linux.rb
    lib/linecook/os/linux/utilities.rb
    lib/linecook/os/posix.rb
    lib/linecook/os/posix/utilities.rb
    lib/linecook/os/posix/variable.rb
    lib/linecook/package.rb
    lib/linecook/proxy.rb
    lib/linecook/recipe.rb
    lib/linecook/test.rb
    lib/linecook/utils.rb
    lib/linecook/version.rb
  }
  s.test_files    = %w{}
  s.executables   = ['linecook']
  s.require_paths = ['lib']
end
