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
  
  #
  # script_test
  #
  
  def test_script_test_passes_if_script_exits_zero
    script_test "exit 0"
  end
  
  def test_script_test_fails_if_script_exits_non_zero
    assert_raises(Test::Unit::AssertionFailedError) { script_test "exit 1" }
  end
  
  def test_script_test_builds_package_and_runs_script_from_package_dir
    script_test %q{
      if [ "$(sh recipe)" = "hello world" ]; then exit 0; fi
      exit 1
    } do
      target.puts 'echo hello world'
    end
  end
  
  def test_script_test_resets_package
    script_test %q{
      if [ "$(sh recipe)" = "hello world" ]; then exit 0; fi
      exit 1
    } do
      target.puts 'echo hello world'
    end
    
    script_test %q{
      if [ "$(sh recipe)" = "goodnight moon" ]; then exit 0; fi
      exit 1
    } do
      target.puts 'echo goodnight moon'
    end
  end
  
  #
  # vbox_test test
  #
  
  def test_end_to_end
    vbox_test %Q{
      % bash recipe | tee one
      hello world
      hello world
      % cat one
      hello world
      hello world
    } do
      target.puts 'echo hello world'
      target.puts 'echo hello world'
    end
  end
  
  def test_end_to_end_two
    vbox_test %Q{
      % bash recipe
      goonight moon
    } do
      target.puts 'echo goonight moon'
    end
  end
end