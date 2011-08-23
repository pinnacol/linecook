require File.expand_path('../../../../test_helper', __FILE__)
require 'linecook/os/linux'
require 'linecook/test'

class LinuxUtilitiesTest < Test::Unit::TestCase
  include Linecook::Test

  def setup
    super
    use_helpers Linecook::Os::Linux
  end

  TEST_USER      = 'test_user'
  TEST_GROUP     = 'test_group'
  TEST_USER_TWO  = 'test_user_two'
  TEST_GROUP_TWO = 'test_group_two'

  def clear_test_users
    setup_recipe do
      cd command_dir
      login do
        writeln %{userdel  #{TEST_USER}      > /dev/null 2>&1}
        writeln %{userdel  #{TEST_USER_TWO}  > /dev/null 2>&1}
        writeln %{groupdel #{TEST_GROUP}     > /dev/null 2>&1}
        writeln %{groupdel #{TEST_GROUP_TWO} > /dev/null 2>&1}
      end
      writeln "true"
    end
  end

  #
  # groupadd test
  #

  def test_groupadd_adds_group
    clear_test_users

    setup_recipe do
      cd command_dir

      login do
        if_ _group?(TEST_GROUP) do
          writeln "exit 1"
        end

        groupadd TEST_GROUP

        unless_ _group?(TEST_GROUP) do
          writeln "exit 1"
        end
      end
    end

    stdout, msg = run_package
    assert_equal 0, $?.exitstatus, msg
  end

  #
  # group? test
  #

  def test_group_check_passes_if_the_group_exists
    clear_test_users

    setup_recipe do
      cd command_dir

      login do
        unless_ _group?("$(id -ng $(whoami))") do
          writeln "exit 1"
        end

        if_ _group?(TEST_GROUP) do
          writeln "exit 1"
        end
      end
    end

    stdout, msg = run_package
    assert_equal 0, $?.exitstatus, msg
  end

  #
  # groupdel test
  #

  def test_groupdel_removes_group
    clear_test_users

    setup_recipe do
      cd command_dir

      login do
        writeln "groupadd #{TEST_GROUP}"

        unless_ _group?(TEST_GROUP) do
          writeln "exit 1"
        end

        groupdel TEST_GROUP

        if_ _group?(TEST_GROUP) do
          writeln "exit 1"
        end
      end
    end

    stdout, msg = run_package
    assert_equal 0, $?.exitstatus, msg
  end

  #
  # groups test
  #

  def test_groups_returns_groups_a_user_belongs_to
    clear_test_users

    setup_recipe do
      cd command_dir

      login do
        writeln "groupadd #{TEST_GROUP}"
        writeln "groupadd #{TEST_GROUP_TWO}"
        writeln "useradd -g #{TEST_GROUP_TWO} -G #{TEST_GROUP} #{TEST_USER}"
      end

      groups(TEST_USER)
    end

    assert_str_equal %{
      #{TEST_USER} : #{TEST_GROUP_TWO} #{TEST_GROUP}
    }, *run_package
  end

  #
  # install test
  #

  def test_install_copies_source_to_target
    setup_recipe 'recipe' do
      cd command_dir
      echo('content').to('source')

      install 'source', 'target'
      cat 'target'
    end

    assert_str_equal %{
      content
    }, *run_package
  end

  def test_install_backs_up_existing_target_if_specified
    setup_recipe 'recipe' do
      cd command_dir
      echo('new').to('source')
      echo('old').to('target')

      install 'source', 'target', :backup => true

      cat 'target~'
      cat 'target'
    end

    assert_str_equal %{
      old
      new
    }, *run_package
  end

  #
  # su test
  #

  CONTEXT_CHECK = 'echo "$(whoami):$(pwd):$VAR"'

  def test_su_makes_script_with_name_and_mode_as_specified
    setup_recipe do
      cd command_dir
      su 'root', :target_name => 'check_name', :mode => 0600 do
        write 'content'
      end
    end

    assert_equal 'content', package.content('check_name')
    assert_equal 0600, package.export_options('check_name')[:mode]
  end

  def test_su_guesses_target_name_from_non_hash_options
    setup_recipe do
      cd command_dir
      su 'root', 'desc' do
        write 'content'
      end
    end

    assert_equal 'content', package.content('desc')
  end

  def test_su_switches_user_for_duration_of_a_block
    setup_recipe do
      set_package_dir command_dir
      cd
      writeln "export VAR=a"
      writeln CONTEXT_CHECK
      su 'root' do
        writeln CONTEXT_CHECK
        writeln "export VAR=b"
        writeln CONTEXT_CHECK
      end
      writeln CONTEXT_CHECK
    end

    assert_str_equal %{
      linecook:/home/linecook:a
      root:/home/linecook:a
      root:/home/linecook:b
      linecook:/home/linecook:a
    }, *run_package
  end

  def test_su_preserves_functions
    setup_recipe do
      cd command_dir
      function "say_hello" do
        echo 'hello $1'
      end
      writeln "say_hello $(whoami)"
      su do
        writeln "say_hello $(whoami)"
      end
      writeln "say_hello $(whoami)"
    end

    assert_str_equal %{
      hello linecook
      hello root
      hello linecook
    }, *run_package
  end

  def test_nested_su
    setup_recipe do
      set_package_dir command_dir
      cd
      writeln "export VAR=a"
      writeln CONTEXT_CHECK
      su 'root' do
        writeln CONTEXT_CHECK
        writeln "export VAR=b"
        writeln CONTEXT_CHECK
        su 'linecook' do
          writeln CONTEXT_CHECK
          writeln "export VAR=c"
          writeln CONTEXT_CHECK
        end
        writeln CONTEXT_CHECK
      end
      writeln CONTEXT_CHECK
    end

    assert_str_equal %{
      linecook:/home/linecook:a
      root:/home/linecook:a
      root:/home/linecook:b
      linecook:/home/linecook:b
      linecook:/home/linecook:c
      root:/home/linecook:b
      linecook:/home/linecook:a
    }, *run_package
  end

  #
  # useradd test
  #

  def test_useradd_adds_user
    clear_test_users

    setup_recipe do
      cd command_dir
      login do
        if_ _user?(TEST_USER) do
          writeln "exit 1"
        end

        useradd TEST_USER

        unless_ _user?(TEST_USER) do
          writeln "exit 1"
        end
      end
    end

    stdout, msg = run_package
    assert_equal 0, $?.exitstatus, msg
  end

  #
  # user? test
  #

  def test_user_check_passes_if_the_user_exists
    clear_test_users

    setup_recipe do
      cd command_dir
      login do
        unless_ _user?("$(whoami)") do
          writeln "exit 1"
        end

        if_ _user?(TEST_USER) do
          writeln "exit 1"
        end
      end
    end

    stdout, msg = run_package
    assert_equal 0, $?.exitstatus, msg
  end

  #
  # userdel test
  #

  def test_userdel_removes_user
    clear_test_users

    setup_recipe do
      cd command_dir
      login do
        writeln "useradd #{TEST_USER}"

        unless_ _user?(TEST_USER) do
          writeln "exit 1"
        end

        userdel TEST_USER

        if_ _user?(TEST_USER) do
          writeln "exit 1"
        end
      end
    end

    stdout, msg = run_package
    assert_equal 0, $?.exitstatus, msg
  end
end