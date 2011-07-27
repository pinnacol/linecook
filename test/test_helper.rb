require 'rubygems'
require 'bundler'
Bundler.setup

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
  end
end