require 'rubygems'
require 'bundler'
runtime = Bundler.setup

# Workaround the performance penalty of reactivating bundler on each system
# call to linecook - see https://github.com/carlhuda/bundler/issues/1323
rubyopt = []
runtime.gems.each do |gemspec|
  gemspec.require_paths.each do |require_path|
    rubyopt.unshift "-I#{File.join(gemspec.full_gem_path, require_path)}"
  end
end
ENV['RUBYOPT']=rubyopt.join(' ')

require 'shell_test/unit'

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end

# Use these instead of setting PATH to bin dir to avoid potential
# warnings about a world writable directory being on PATH
LINECOOK_PATH = File.expand_path('../../bin/linecook', __FILE__)
LINECOOK_EXE  = "ruby '#{LINECOOK_PATH}'"
