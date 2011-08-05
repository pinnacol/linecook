require File.expand_path('../test_helper', __FILE__)
require 'linecook/test'

class LinecookTest < Test::Unit::TestCase
  include Linecook::Test

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
      write 'echo hello world'
    }

    assert_script %{
      $ linecook compile '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal "echo hello world", content('recipe/run')
  end

  def test_compile_builds_multiple_recipes
    a = prepare 'path/to/a.rb', %{
      write 'echo hello a'
    }
    b = prepare 'b.rb', %{
      write 'echo hello b'
    }

    assert_script %{
      $ linecook compile '#{a}' '#{b}'
      #{path('a')}
      #{path('b')}
    }

    assert_equal "echo hello a", content('a/run')
    assert_equal "echo hello b", content('b/run')
  end

  def test_compile_allows_specification_of_an_alternate_output_dir
    recipe_path = prepare 'recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ linecook compile -opackage '#{recipe_path}'
      #{path('package/recipe')}
    }

    assert_equal "echo hello world", content('package/recipe/run')
  end

  def test_compile_raises_error_if_package_dir_exists
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'new'
    }
    prepare 'recipe/run', 'current'

    assert_script %{
      $ linecook compile '#{recipe_path}' 2>&1 # [1]
      already exists: "#{path('recipe')}"
    }
  
    assert_equal 'current', content('recipe/run')
  end

  def test_compile_overwrites_package_dir_on_force
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'new'
    }
    prepare 'recipe/run', 'current'

    assert_script %{
      $ linecook compile -f '#{recipe_path}'
      #{path('recipe')}
    }
  
    assert_equal 'new', content('recipe/run')
  end

  def test_compile_allows_specification_of_an_alternate_script_name
    recipe_path = prepare 'recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ linecook compile -stest '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo hello world', content('recipe/test')
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
          write "echo #{str}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      require 'echo'
      extend Echo
      echo 'hello world'
    }

    assert_script %{
      $ linecook compile -Ilib '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo hello world', content('recipe/run')
  end

  def test_compile_allows_specification_of_requires
    echo_path = prepare 'lib/echo.rb', %q{
      module Echo
        def echo(str)
          write "echo #{str}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      extend Echo
      echo 'hello world'
    }

    assert_script %{
      $ linecook compile -r'#{echo_path}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo hello world', content('recipe/run')
  end

  def test_compile_compiles_helpers_if_specified
    prepare('helpers/example/echo.rb', %q{
      (str)
      ---
      write "echo #{str}"
    })

    recipe_path = prepare 'recipe.rb', %{
      helper 'example'
      echo 'hello world'
    }

    assert_script %{
      $ linecook compile -H helpers '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo hello world', content('recipe/run')
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
      $ linecook compile -H helpers '#{recipe_path}'
      #{path('recipe')}
    }

    assert_str_equal %{
      cat <<DOC
      a
      b
      c
      DOC
    }, content('recipe/run')
  end

  def test_compiled_helpers_allow_capture
    prepare 'helpers/example/echo.erb', %q{
      (str)
      --
      echo <%= str %>
    }

    recipe_path = prepare 'recipe.rb', %q{
      helper 'example'
      write _echo('xyz').upcase
    }

    assert_script %{
      $ linecook compile -H helpers '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal "ECHO XYZ", content('recipe/run')
  end

  def test_compile_copies_added_files_to_package_dir
    file_path = prepare 'file.txt', 'content'
    recipe_path = prepare 'recipe.rb', %{
      _package_.add 'pkgfile.txt', '#{file_path}'
    }

    assert_script %{
      $ linecook compile '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal "content", content('file.txt')
    assert_equal "content", content('recipe/pkgfile.txt')
  end

  def test_compile_moves_files_marked_for_move
    file_path = prepare 'file.txt', 'content'
    recipe_path = prepare 'recipe.rb', %{
      _package_.add 'pkgfile.txt', '#{file_path}'
      _package_.on_export 'pkgfile.txt', :move => true
    }

    assert_script %{
      $ linecook compile '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal false, File.exists?(file_path)
    assert_equal "content", content('recipe/pkgfile.txt')
  end

  def test_compile_need_not_generate_a_script
    recipe_path = prepare 'recipe.rb', %{
      _package_.unregister target
    }

    assert_script %{
      $ linecook compile '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal [], Dir.glob(path('recipe/*'))
  end

  def test_compile_can_specify_a_package_file_defining_recipe_attrs
    package_file = prepare 'package.yml', %{
      key: value
    }
    recipe_path  = prepare 'recipe.rb', %{
      write attrs['key']
    }

    assert_script %{
      $ linecook compile -P '#{package_file}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'value', content('recipe/run')
  end

  def test_compile_can_specify_attributes_directories
    prepare 'attributes/example.yml', %{
      key: value
    }
    recipe_path  = prepare 'recipe.rb', %{
      attributes 'example'
      write attrs['key']
    }

    assert_script %{
      $ linecook compile -A '#{path('attributes')}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'value', content('recipe/run')
  end

  def test_compile_can_specify_attributes_directories_as_a_path
    prepare 'one/a.yml', %{
      a: one
    }
    prepare 'two/b.yml', %{
      b: two
    }
    recipe_path  = prepare 'recipe.rb', %{
      attributes 'a'
      attributes 'b'
      write attrs['a']
      write attrs['b']
    }

    assert_script %{
      $ linecook compile -A '#{path('one')}:#{path('two')}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'onetwo', content('recipe/run')
  end

  def test_compile_can_specify_file_directories
    prepare 'files/example.txt', 'content'
    recipe_path = prepare 'recipe.rb', %{
      write file_path('example.txt')
    }

    assert_script %{
      $ linecook compile -F '#{path('files')}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'example.txt', content('recipe/run')
    assert_equal 'content', content('recipe/example.txt')
  end

  def test_compile_can_specify_recipe_directories
    prepare 'recipes/example.rb', %{
      write 'content'
    }
    recipe_path = prepare 'recipe.rb', %{
      write recipe_path('example.rb')
    }

    assert_script %{
      $ linecook compile -R '#{path('recipes')}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'example', content('recipe/run')
    assert_equal 'content', content('recipe/example')
  end

  #
  # compile_helper test
  #

  def test_compile_helper_compiles_source_files_to_helper_module
    source_file = prepare 'echo.erb', %{
      (str)
      --
      echo <%= str %>
    }

    recipe_path = prepare 'recipe.rb', %q{
      helper 'example'
      echo 'abc'
    }

    assert_script %{
      $ linecook compile_helper Example '#{source_file}'
      #{path('lib/example.rb')}
      $ linecook compile -Ilib '#{recipe_path}'
      #{path('recipe')}
    }

    assert_str_equal %{
      echo abc
    }, content('recipe/run')
  end

  def test_compile_helper_searches_for_source_files_by_const_path_under_search_dirs
    prepare 'a/example/echo_a.erb', %{
      (str)
      --
      echo a <%= str %>
    }
    prepare 'b/example/echo_b.erb', %{
      (str)
      --
      echo b <%= str %>
    }
    recipe_path = prepare 'recipe.rb', %q{
      helper 'example'
      echo_a 'abc'
      echo_b 'xyz'
    }

    assert_script %{
      $ linecook compile_helper Example -s '#{path('a')}' -s '#{path('b')}'
      #{path('lib/example.rb')}
      $ linecook compile -Ilib '#{recipe_path}'
      #{path('recipe')}
    }

    assert_str_equal %{
      echo a abc
      echo b xyz
    }, content('recipe/run')
  end

  def test_compile_helper_has_sensible_error_for_no_sources_specified
    assert_script %{
      $ linecook compile_helper Example # [1]
      no sources specified
    }
  end

  def test_compile_helper_has_sensible_error_for_invalid_constant_name
    assert_script %{
      $ linecook compile_helper _Example # [1]
      invalid constant name: "_Example"
    }
  end

  def test_compile_helper_has_sensible_error_for_invalid_source_file_names
    source_file = prepare('-.rb', '')
    assert_script %{
      $ linecook compile_helper Example '#{source_file}' # [1]
      invalid source file: "#{source_file}" (invalid method name "-")
    }
  end

  def test_compile_helper_has_sensible_error_for_invalid_formats
    source_file = prepare('source_file.json', '')
    assert_script %{
      $ linecook compile_helper Example '#{source_file}' # [1]
      invalid source file: "#{source_file}" (unsupported format ".json")
    }
  end

  def test_compile_helper_has_sensible_error_for_invalid_section_formats
    source_file = prepare('_section_file.json', '')
    assert_script %{
      $ linecook compile_helper Example '#{source_file}' # [1]
      invalid source file: "#{source_file}" (unsupported section format ".json")
    }
  end
end
