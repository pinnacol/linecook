require 'rubygems'
require 'bundler'
runtime = Bundler.setup

# Workaround the performance penalty of reactivating bundler on each system
# call to linecook - see https://github.com/carlhuda/bundler/issues/1323
path, rubyopt = [], []
runtime.gems.each do |gemspec|
  path.unshift File.join(gemspec.full_gem_path, gemspec.bindir)
  gemspec.require_paths.each do |require_path|
    rubyopt.unshift "-I#{File.join(gemspec.full_gem_path, require_path)}"
  end
end
ENV['RUBYOPT']=rubyopt.join(' ')
ENV['PATH']="#{path.join(':')}:#{ENV['PATH']}"

require 'shell_test/unit'

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end

# patches
module ShellTest
  module FileMethods
    alias _prepare prepare
    def prepare(path, content=nil, &block)
      content = outdent(content) if content
      _prepare(path, content, &block)
    end

    def content(relative_path)
      File.read path(relative_path)
    end
  end
end