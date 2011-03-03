require File.expand_path('../../../test_helper', __FILE__) 
require 'linecook/commands/build'
require 'linecook/test'

class BuildCommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Build = Linecook::Commands::Build
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Build.new
  end
  
  #
  # cmd test
  #
  
  def test_build_builds_helper_for_empty_helper_dir
    dir = path('helpers/const/name')
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    
    helper_file = path('lib/const/name.rb')
    assert_equal false, File.file?(helper_file)
    
    sh "ruby #{LINECOOK} build --project-dir '#{method_dir}'"
    assert_equal true, File.file?(helper_file)
  end
end