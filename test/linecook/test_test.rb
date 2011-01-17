require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class LinecookTestTest < Test::Unit::TestCase
  include Linecook::Test
  
  def cookbook_dir
    method_dir
  end
  
  #
  # setup_package test
  #
  
  def test_setup_package_and_package_testing
    file('recipes/example.rb') {|io| io << "target << Array.new(attrs['n'], 'success').join(',')"}
    
    setup_package 'linecook' => {'recipes' => 'example'}, 'n' => 3
    package.build
    
    assert_equal "success,success,success", package.content('example')
  end
  
  #
  # script_test
  #
  
  def test_script_test_builds_and_script_from_recipe_and_compares_output_to_expected
    script_test %q{
      % sh recipe
      hello world
    } do
      target.puts 'echo hello world'
    end
  end
  
  def test_script_test_resets_package
    script_test %q{
      % sh recipe
      hello world
    } do
      target.puts 'echo hello world'
    end
    
    script_test %q{
      % sh recipe
      goodnight moon
    } do
      target.puts 'echo goodnight moon'
    end
  end
  
  def test_script_test_executes_in_packages_dir_under_method_root
    script_test %Q{
      % sh recipe
      #{path('packages')}
    } do
      target.puts 'pwd'
    end
  end
  
  #
  # assert_output_equal test
  #

  def test_assert_output_equal_documentation
    assert_output_equal %q{
line one
line two
}, "line one\nline two\n"

    assert_output_equal %q{
  line one
  line two
}, "line one\nline two\n"

    assert_output_equal %q{
    line one
    line two
    }, "line one\nline two\n"
  end

  def test_assert_output_equal
    assert_output_equal %q{
    line one
      line two
    }, "line one\n  line two\n"

    assert_output_equal %q{
    line one
      line two}, "line one\n  line two"

    assert_output_equal %Q{  \t   \r
    line one
    line two
    }, "line one\nline two\n"

    assert_output_equal %q{
    
    
    }, "\n\n"

    assert_output_equal %q{
    
    }, "\n"

    assert_output_equal %Q{  \t   \r
    
    }, "\n"

    assert_output_equal %q{
    }, ""

    assert_output_equal %q{}, ""
    assert_output_equal %q{line one
line two
}, "line one\nline two\n"
  end

  #
  # assert_output_equal! test
  #

  def test_assert_output_equal_bang_does_not_strip_indentation
    assert_output_equal! %q{
    }, "\n    "
  end

  #
  # assert_alike test
  #

  def test_assert_alike_documentation
    assert_alike %q{
the time is: :...:
now!
}, "the time is: #{Time.now}\nnow!\n"

    assert_alike %q{
  the time is: :...:
  now!
}, "the time is: #{Time.now}\nnow!\n"

    assert_alike %q{
    the time is: :...:
    now!
    }, "the time is: #{Time.now}\nnow!\n"
  end

  def test_assert_alike
    assert_alike(/abc/, "...abc...")
  end

  def test_assert_alike_regexp_escapes_strings
    assert_alike "a:...:c", "...alot of random stuff toc..."
  end
end