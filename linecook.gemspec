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
  }

  # add dependencies
  s.add_dependency('config_parser', '~> 0.5.5')
  s.add_dependency('configurable', '~> 1.0')
  s.add_development_dependency('bundler', '~> 1.0')
  s.add_development_dependency('rcov', '~> 0.9')
  s.add_development_dependency('shell_test', '~> 0.2.0')

  s.files         = %w{}
  s.test_files    = %w{}
  s.executables   = ['linecook']
  s.require_paths = ['lib']
end
