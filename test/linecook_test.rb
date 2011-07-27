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
    recipe_path = prepare 'path/to/recipe.rb', %{
      writeln 'echo hello world'
    }
    
    assert_script %{
      $ linecook compile '#{recipe_path}'
      #{Dir.pwd}/recipe
      $ . '#{Dir.pwd}/recipe/run'
      hello world
    }
  end

  def test_compile_builds_multiple_recipes
    a = prepare 'path/to/a.rb', %{
      writeln 'echo hello a'
    }
    b = prepare 'b.rb', %{
      writeln 'echo hello b'
    }

    assert_script_match %{
      $ linecook compile '#{a}' '#{b}'
      #{Dir.pwd}/a
      #{Dir.pwd}/b
      $ . '#{Dir.pwd}/a/run'
      hello a
      $ . '#{Dir.pwd}/b/run'
      hello b
    }
  end

  def test_compile_allows_specification_of_an_alternate_output_dir
    recipe_path = prepare 'recipe.rb', %{
      writeln 'echo hello world'
    }

    assert_script %{
      $ linecook compile -opackage '#{recipe_path}'
      #{Dir.pwd}/package/recipe
    }
  end

  def test_compile_allows_specification_of_an_alternate_script_name
    recipe_path = prepare 'recipe.rb', %{
      writeln 'echo hello world'
    }

    assert_script %{
      $ . "$(linecook compile -stest '#{recipe_path}')"/test
      hello world
    }
  end

  def test_compile_allows_script_to_be_made_executable
    recipe_path = prepare 'recipe.rb', %{
      writeln 'echo hello world'
    }

    assert_script %{
      $ "$(linecook compile -x '#{recipe_path}')"/run
      hello world
    }
  end

  def test_compile_allows_specification_of_load_paths
    prepare 'lib/echo.rb', %q{
      module Echo
        def echo(str)
          writeln "echo #{str}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      require 'echo'
      extend Echo
      echo 'hello world'
    }

    assert_script %{
      $ . "$(linecook compile -Ilib '#{recipe_path}')"/run
      hello world
    }
  end

  def test_compile_allows_specification_of_requires
    echo_path = prepare 'lib/echo.rb', %q{
      module Echo
        def echo(str)
          writeln "echo #{str}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      extend Echo
      echo 'hello world'
    }

    assert_script %{
      $ . "$(linecook compile -r'#{echo_path}' '#{recipe_path}')"/run
      hello world
    }
  end

  def test_compile_compiles_helpers_if_specified
    prepare('helpers/example/echo.rb', %q{
      (str)
      ---
      writeln "echo #{str}"
    })

    recipe_path = prepare 'recipe.rb', %{
      helper 'example'
      echo 'hello world'
    }

    assert_script %{
      $ . "$(linecook compile -H helpers '#{recipe_path}' 2>&1)"/run
      hello world
    }
  end

  def test_compiled_helpers_allow_method_chaining
    prepare 'helpers/example/cat.erb', %{
      cat
    }

    prepare 'helpers/example/heredoc.erb', %{
      ()
      _rstrip_ if _chain_?
      --
       <<DOC
      <% yield %>
      DOC
    }

    recipe_path = prepare 'recipe.rb', %{
      helper 'example'
      cat.heredoc do
        writeln 'a'
        writeln 'b'
        writeln 'c'
      end
    }

    assert_script %{
      $ . "$(linecook compile -H helpers '#{recipe_path}' 2>&1)"/run
      a
      b
      c
    }
  end
  
  def test_compiled_helpers_allow_capture
    prepare 'helpers/example/wrln.rb', %q{
      (str)
      --
      writeln str
    }

    recipe_path = prepare 'recipe.rb', %q{
      helper 'example'
      wrln "echo abc"
      writeln "echo #{_wrln('xyz').upcase}"
    }

    assert_script %{
      $ . "$(linecook compile -H helpers '#{recipe_path}' 2>&1)"/run
      abc
      XYZ
    }
  end
end
