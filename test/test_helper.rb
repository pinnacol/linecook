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

# Updates ShellTest::FileMethods in the same way as Linecook::Test such that
# multitesting is possible.  Include after ShellTest::FileMethods.
module FileMethodsShim
  def method_dir
    @host_method_dir ||= begin
      if test_host = ENV['LINECOOK_TEST_HOST']
        File.join(super, test_host)
      else
        super
      end
    end
  end
end

# Patch
module ShellTest
  module FileTestMethods
    def prepare_dir(relative_path)
      target_dir = path(relative_path)
      unless File.directory?(target_dir)
        FileUtils.mkdir_p(target_dir)
      end
      target_dir
    end
  end
end
