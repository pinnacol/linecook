require File.expand_path('../test_helper', __FILE__)

class LinecookTest < Test::Unit::TestCase
  include ShellTest

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

  def test_compile_builds_the_recipe_in_a_dir_named_like_the_recipe_minus_extname
    skip "not ready yet..."
    recipe_path = prepare('recipe.rb') do |io|
      io << "writeln 'echo hello world'"
    end

    assert_script_match %{
      $ linecook compile #{recipe_path}
      #{recipe_path.chomp('.rb')}
      $ . #{recipe_path.chomp('.rb')}/run
      hello world
    }
  end

  def test_compile_guesses_with_d_extname_for_recipes_without_extname
    skip "not ready yet..."
    recipe_path = prepare('recipe') {}
    assert_script_match %{
      $ linecook compile #{recipe_path}
      recipe.d
    }
  end

  def test_compile_allows_specification_of_an_alternate_package_dir
    skip "not ready yet..."
    recipe_path = prepare('recipe.rb') {}
    assert_script_match %{
      $ linecook compile -dpackage #{recipe_path}
      package/recipe
    }
  end

  def test_compile_allows_specification_of_an_alternate_script_name
    skip "not ready yet..."
    recipe_path = prepare('recipe.rb') do |io|
      io << "writeln 'echo hello world'"
    end

    assert_script_match %{
      $ linecook compile -stest #{recipe_path}
      #{recipe_path.chomp('.rb')}
      $ . #{recipe_path.chomp('.rb')}/test
      hello world
    }
  end

  def test_compile_execute_syntax
    skip "not ready yet..."
    recipe_path = prepare('recipe.rb') do |io|
      io << "writeln 'echo hello world'"
    end

    assert_script_match %{
      $ $(linecook compile #{recipe_path})/run
      hello world
    }
  end
end
