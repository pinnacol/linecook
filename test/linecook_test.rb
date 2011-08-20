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
    super.each {|triplet| triplet[0] = "2>&1 #{triplet[0].sub('linecook', LINECOOK_EXE)}" }
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

  def test_compile_builds_the_recipe_in_a_file_under_pwd_named_like_the_recipe
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ linecook compile '#{recipe_path}'
    }

    assert_equal "echo hello world", content('path/to/recipe')
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
    }

    assert_equal "echo hello a", content('path/to/a')
    assert_equal "echo hello b", content('b')
  end

  def test_compile_allows_specification_of_output_dir
    recipe_path = prepare 'recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ linecook compile -o dir '#{recipe_path}'
    }

    assert_equal "echo hello world", content('dir/recipe')
  end

  def test_compile_raises_error_if_script_exists
    recipe_path = prepare 'recipe.rb', %{
      write 'new'
    }
    prepare 'recipe', 'current'

    assert_script %{
      $ linecook compile '#{recipe_path}' 2>&1 # [1]
      already exists: "#{path('recipe')}"
    }

    assert_equal 'current', content('recipe')
  end

  def test_compile_overwrites_existing_script_on_force
    recipe_path = prepare 'recipe.rb', %{
      capture_path 'run', 'new'
    }
    prepare 'recipe', 'current'

    assert_script %{
      $ linecook compile -f '#{recipe_path}'
    }

    assert_equal 'new', content('recipe')
  end

  def test_compile_allows_specification_of_load_paths
    prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      require 'echo'
      extend Echo
      upper_echo 'hello world'
    }

    assert_script %{
      $ linecook compile -Ilib '#{recipe_path}'
    }

    assert_equal 'echo HELLO WORLD', content('recipe')
  end

  def test_compile_allows_specification_of_requires
    echo_path = prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      extend Echo
      upper_echo 'hello world'
    }

    assert_script %{
      $ linecook compile -r'#{echo_path}' '#{recipe_path}'
    }

    assert_equal 'echo HELLO WORLD', content('recipe')
  end

  def test_compile_compiles_helpers_if_specified
    prepare 'helpers/example/upper_echo.rb', %q{
      (str)
      ---
      write "echo #{str.upcase}"
    }

    recipe_path = prepare 'recipe.rb', %{
      helper 'example'
      upper_echo 'hello world'
    }

    assert_script %{
      $ linecook compile -L helpers '#{recipe_path}'
    }

    assert_equal 'echo HELLO WORLD', content('recipe')
  end

  #
  # package test
  #

  def test_package_builds_the_recipe_in_a_dir_under_pwd_named_like_the_recipe_basename
    recipe_path = prepare 'path/to/recipe.rb', %{
      capture_path 'run', 'echo hello world'
    }

    assert_script %{
      $ linecook package '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal "echo hello world", content('recipe/run')
  end

  def test_package_builds_multiple_recipes
    a = prepare 'path/to/a.rb', %{
      capture_path 'run', 'echo hello a'
    }
    b = prepare 'b.rb', %{
      capture_path 'run', 'echo hello b'
    }

    assert_script %{
      $ linecook package '#{a}' '#{b}'
      #{path('a')}
      #{path('b')}
    }

    assert_equal "echo hello a", content('a/run')
    assert_equal "echo hello b", content('b/run')
  end

  def test_package_allows_specification_of_an_alternate_output_dir
    recipe_path = prepare 'recipe.rb', %{
      capture_path 'run', 'echo hello world'
    }

    assert_script %{
      $ linecook package -o '#{path('package')}' '#{recipe_path}'
      #{path('package/recipe')}
    }

    assert_equal "echo hello world", content('package/recipe/run')
  end

  def test_package_raises_error_if_package_dir_exists
    recipe_path = prepare 'path/to/recipe.rb', %{
      capture_path 'run', 'new'
    }
    prepare 'recipe/run', 'current'

    assert_script %{
      $ linecook package '#{recipe_path}' 2>&1 # [1]
      already exists: "#{path('recipe')}"
    }

    assert_equal 'current', content('recipe/run')
  end

  def test_package_overwrites_package_dir_on_force
    recipe_path = prepare 'path/to/recipe.rb', %{
      capture_path 'run', 'new'
    }
    prepare 'recipe/run', 'current'

    assert_script %{
      $ linecook package -f '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'new', content('recipe/run')
  end

  def test_package_allows_specification_of_load_paths
    prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      require 'echo'
      extend Echo
      capture_path 'run' do
        upper_echo 'hello world'
      end
    }

    assert_script %{
      $ linecook package -Ilib '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo HELLO WORLD', content('recipe/run')
  end

  def test_package_allows_specification_of_requires
    echo_path = prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      extend Echo
      capture_path 'run' do
        upper_echo 'hello world'
      end
    }

    assert_script %{
      $ linecook package -r'#{echo_path}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo HELLO WORLD', content('recipe/run')
  end

  def test_package_compiles_helpers_if_specified
    prepare 'helpers/example/upper_echo.rb', %q{
      (str)
      ---
      write "echo #{str.upcase}"
    }

    recipe_path = prepare 'recipe.rb', %{
      helper 'example'
      capture_path 'run' do
        upper_echo 'hello world'
      end
    }

    assert_script %{
      $ linecook package -L helpers '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo HELLO WORLD', content('recipe/run')
  end

  def test_package_guesses_a_package_file
    package_file = prepare 'recipe.yml', %{
      key: value
    }
    recipe_path  = prepare 'recipe.rb', %{
      capture_path 'run', attrs['key']
    }

    assert_script %{
      $ linecook package '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'value', content('recipe/run')
  end

  def test_package_allows_specification_of_an_alternate_input_dir
    prepare 'packages/recipe.yml', %{
      key: value
    }
    recipe_path  = prepare 'recipe.rb', %{
      capture_path 'run', attrs['key']
    }

    assert_script %{
      $ linecook package -i '#{path('package')}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'value', content('recipe/run')
  end

  def test_package_can_specify_cookbook_directories
    prepare 'attributes/example.yml', 'obj: milk'
    prepare 'templates/example.erb', 'got <%= obj %>'
    recipe_path = prepare 'recipe.rb', %{
      attributes 'example'
      capture_path 'run', render('example', attrs)
    }

    assert_script %{
      $ linecook package -C '#{method_dir}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'got milk', content('recipe/run')
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
    }

    assert_str_equal %{
      echo abc
    }, content('recipe')
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
    }

    assert_str_equal %{
      echo a abc
      echo b xyz
    }, content('recipe')
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

  #
  # run test
  #

  def relative_dir
    method_dir[(user_dir.length + 1)..-1]
  end

  def test_run_runs_package_on_host_given_by_package_dir
    path = prepare('abox/run', 'echo "on $(hostname)"')
    FileUtils.chmod(0744, path)

    Dir.chdir(user_dir) do
      assert_script %{
        $ linecook run -q -D 'vm/#{relative_dir}' '#{path('abox')}'
        on abox-ubuntu
      }
    end
  end

  def test_run_exits_with_status_1_for_failed_script
    path = prepare('abox/run', 'exit 8')
    FileUtils.chmod(0744, path)

    Dir.chdir(user_dir) do
      assert_script %Q{
        $ linecook run -q -D 'vm/#{relative_dir}' '#{path('abox')}' # [1] ...
      }
    end
  end

  def test_run_exits_with_status_1_for_missing_run_script
    prepare_dir('abox')

    Dir.chdir(user_dir) do
      assert_script %Q{
        $ linecook run -q -D 'vm/#{relative_dir}' '#{path('abox')}' # [1] ...
      }
    end
  end

  def test_run_runs_each_package
    ['abox', 'bbox'].each do |box|
      path = prepare("#{box}/run", 'echo "on $(hostname)"')
      FileUtils.chmod(0744, path)
    end

    Dir.chdir(user_dir) do
      assert_script %Q{
        $ linecook run -q -D 'vm/#{relative_dir}' '#{path('abox')}' '#{path('bbox')}'
        on abox-ubuntu
        on bbox-ubuntu
      }
    end
  end
end
