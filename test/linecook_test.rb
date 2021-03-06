require File.expand_path('../test_helper', __FILE__)
require 'linecook/test'

class LinecookTest < Test::Unit::TestCase
  include Linecook::Test
  
  def setup
    super
    FileUtils.mkdir_p method_dir
    Dir.chdir method_dir
  end

  def teardown
    Dir.chdir user_dir
    super
  end
  
  def test_linecook_generates_a_cookbook_directory
    example_dir = path('example')
    assert_equal false, File.exists?(example_dir)
    
    output = `2>&1 ruby #{LINECOOK} init example`
    assert_equal 0, $?.exitstatus, output
    
    Dir.chdir(example_dir) do
      gemfile = File.expand_path('Gemfile')
      File.open(gemfile, 'w') do |io|
        io.puts %Q{
          path '#{LINECOOK_DIR}', :glob => 'linecook.gemspec'
          gemspec
        }
      end
      
      output = `BUNDLE_GEMFILE='#{gemfile}' 2>&1 bundle exec linecook helper example`
      assert_equal 0, $?.exitstatus, output
      
      output = `BUNDLE_GEMFILE='#{gemfile}' 2>&1 bundle exec linecook package packages/abox.yml`
      assert_equal 0, $?.exitstatus, output
      assert_equal true, File.exists?('packages/abox/run'), output
      
      output = `BUNDLE_GEMFILE='#{gemfile}' 2>&1 bundle exec rake quicktest`
      assert_equal 0, $?.exitstatus, output.gsub(/^/, '>')
    end
  end
  
  def test_init_does_not_overwrite_existing_directory
    example_dir = path('example')
    FileUtils.mkdir_p(example_dir)
    
    output = `2>&1 ruby #{LINECOOK} init example`
    assert_equal 1, $?.exitstatus
    
    assert_equal [], Dir.glob("#{example_dir}/*")
  end
  
  def test_init_does_not_allow_force_for_parent_dirs_or_current_dir
    example_dir = path('parent/current')
    FileUtils.mkdir_p(example_dir)
    
    Dir.chdir(example_dir)
    output = `2>&1 ruby #{LINECOOK} init . --force`
    assert_equal 1, $?.exitstatus
    
    output = `2>&1 ruby #{LINECOOK} init .. --force`
    assert_equal 1, $?.exitstatus
    
    assert_equal [example_dir], Dir.glob(path('parent/*'))
    assert_equal [], Dir.glob(path('parent/current/*'))
  end
end