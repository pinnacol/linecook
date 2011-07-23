require File.expand_path('../test_helper', __FILE__)

class LinecookTest < Test::Unit::TestCase
  include ShellTest

  def setup
    super
    FileUtils.mkdir_p(method_dir)
    Dir.chdir(method_dir)
  end

  def parse_script(script, options={})
    super.each {|triplet| triplet[0] = "2>&1 #{triplet[0]}" }
  end

  def test_linecook_prints_version_and_website
    assert_script %Q{
      $ linecook -v
      linecook version #{Linecook::VERSION} -- #{Linecook::WEBSITE}
    }
  end

  def test_linecook_prints_help
    assert_script_match %q{
      $ linecook -h
      usage: linecook [options] COMMAND [ARGS]
    }
  end

  def test_linecook_prints_help_when_no_args_are_given
    assert_script_match %q{
      $ linecook
      usage: linecook [options] COMMAND [ARGS]
    }
  end

  def test_linecook_prints_command_help
    assert_script_match %q{
      $ linecook compile -h
      usage: linecook compile :...:
    }
  end

  #
  # compile test
  #

  def test_compile_builds_the_recipe_in_a_dir_under_pwd_named_like_the_recipe
    recipe_path = prepare('path/to/recipe.rb', %{
      writeln 'echo hello world'
    })
    
    assert_script_match %{
      $ linecook compile #{recipe_path}
      recipe
      $ . recipe/run
      hello world
    }
  end

  def test_compile_allows_specification_of_an_alternate_output_dir
    recipe_path = prepare('recipe.rb', %{
      writeln 'echo hello world'
    })

    assert_script_match %{
      $ linecook compile -opackage #{recipe_path}
      package/recipe
    }
  end

  def test_compile_allows_specification_of_an_alternate_script_name
    recipe_path = prepare('recipe.rb', %{
      writeln 'echo hello world'
    })

    assert_script_match %{
      $ linecook compile -stest #{recipe_path}
      recipe
      $ . recipe/test
      hello world
    }
  end

  def test_compile_execute_syntax_works
    recipe_path = prepare('recipe.rb', %{
      writeln 'echo hello world'
    })

    assert_script_match %{
      $ $(linecook compile #{recipe_path})/run
      hello world
    }
  end
end
