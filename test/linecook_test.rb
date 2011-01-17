require File.expand_path('../test_helper', __FILE__)
require 'linecook/test'

class LinecookTest < Test::Unit::TestCase
  include Linecook::Test
  
  LINE_COOK_DIR = File.expand_path('../..', __FILE__)
  LINE_COOK = File.join(LINE_COOK_DIR, 'bin/linecook')
  
  def test_linecook_generates_a_cookbook_directory
    example_dir = path('example')
    assert_equal false, File.exists?(example_dir)
    
    output = `ruby #{LINE_COOK} init example`
    assert_equal 0, $?.exitstatus, output
    
    Dir.chdir(example_dir) do
      gemfile = File.expand_path('Gemfile')
      File.open(gemfile, 'w') do |io|
        io.puts %Q{
          path '#{LINE_COOK_DIR}', :glob => 'linecook.gemspec'
          gemspec
        }
      end
      
      output = `BUNDLE_GEMFILE='#{gemfile}' bundle exec linecook helpers`
      assert_equal 0, $?.exitstatus, output
      
      output = `BUNDLE_GEMFILE='#{gemfile}' bundle exec linecook package packages/example.yml`
      assert_equal 0, $?.exitstatus, output
      assert_equal true, File.exists?('packages/example/example'), output
      
      sh_test %q{
        % sh packages/example/example
        a b c
        7 8 9
        Contents of an example file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
        Contents of a template file.
      }
    end
  end
  
  def test_init_does_not_overwrite_existing_directory
    example_dir = path('example')
    FileUtils.mkdir_p(example_dir)
    
    output = `ruby #{LINE_COOK} init example`
    assert_equal 1, $?.exitstatus
    
    assert_equal [], Dir.glob("#{example_dir}/*")
  end
  
  def test_init_regenerates_cookbook_on_force
    example_readme = path('example/README')
    
    output = `ruby #{LINE_COOK} init example`
    assert_equal 0, $?.exitstatus, output
    
    assert_equal true, File.exists?(example_readme)
    FileUtils.rm(example_readme)
    
    output = `ruby #{LINE_COOK} init example --force`
    assert_equal 0, $?.exitstatus, output
    
    assert_equal true, File.exists?(example_readme)
  end
  
  def test_init_does_not_allow_force_for_parent_dirs_or_current_dir
    example_dir = path('parent/current')
    FileUtils.mkdir_p(example_dir)
    
    Dir.chdir(example_dir)
    output = `ruby #{LINE_COOK} init . --force`
    assert_equal 1, $?.exitstatus
    
    output = `ruby #{LINE_COOK} init .. --force`
    assert_equal 1, $?.exitstatus
    
    assert_equal [example_dir], Dir.glob(path('parent/*'))
    assert_equal [], Dir.glob(path('parent/current/*'))
  end
  
  #
  # env test
  #
  
  def test_env_prints_the_current_env
    result = sh "ruby #{LINE_COOK} env"
    result = YAML.load(result)
    
    assert_equal({}, result['linecook']['manifest'])
  end
  
  #
  # vbox test
  #
  
  def test_vbox_
    sh "ruby #{LINE_COOK} reset"
    sh_test %Q{
      % ruby #{LINE_COOK} ssh 'echo hello'
      hello
    }
    sh "ruby #{LINE_COOK} stop"
  end
  
  def test_end_to_end
    script_test %Q{
      % ruby #{LINE_COOK} reset
      % ruby #{LINE_COOK} share "$TEST_PACKAGE_DIR"
      % ruby #{LINE_COOK} ssh "bash /vbox/$TEST_SCRIPT_PATH"
      hello
      % ruby #{LINE_COOK} ssh "ls /vbox"
      recipe
      % ruby #{LINE_COOK} stop
    } do
      target.puts 'echo hello'
    end
  end
end