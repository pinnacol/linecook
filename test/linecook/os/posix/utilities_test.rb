require File.expand_path('../../../../test_helper', __FILE__)
require 'linecook/os/posix'
require 'linecook/test'

class PosixUtilitiesTest < Test::Unit::TestCase
  include Linecook::Test

  def setup
    super
    use_helpers Linecook::Os::Posix
  end

  #
  # pipeline test
  #

  def test_tomayko_word_count
    setup_recipe do
      function :word_count do |n|
        tr("A-Za-z", '\n', :c => true).
        grep('^$', :v => true).
        sort.
        uniq(:c => true).
        sort(:r => true, :n => true).
        head(:n => n)
      end

      word_count(5).heredoc do
        writeln %{
The Project Gutenberg EBook of A Modest Proposal, by Jonathan Swift

Title: A Modest Proposal
       For preventing the children of poor people in Ireland,
       from being a burden on their parents or country, and for
       making them beneficial to the publick - 1729

Author: Jonathan Swift

Posting Date: July 27, 2008 [EBook #1080]
Release Date: October 1997

Language: English

A MODEST PROPOSAL

For preventing the children of poor people in Ireland...
}
      end
    end

    _assert_str_equal %{
      3 the
      3 of
      3 A
      2 Swift
      2 Proposal
}.sub("\n", ''), *run_package
  end

  #
  # cat test
  #

  def test_cat_allows_chaining
    setup_recipe do
      cat.heredoc do
        writeln "a"
        writeln "b"
        writeln "c"
      end
    end

    assert_str_equal %{
      a
      b
      c
    }, *run_package
  end

  #
  # cd test
  #

  def test_cd_changes_dir
    setup_recipe do
      mkdir '/tmp/a/b', :p => true

      cd '/tmp'
      pwd
      cd 'a' do
        pwd
        cd 'b'
        pwd
      end
      pwd
    end

    assert_str_equal %{
      /tmp
      /tmp/a
      /tmp/a/b
      /tmp
    }, *run_package
  end

  #
  # chgrp test
  #

  # Don't know how to encapsulate test chgrp at this point... technically user
  # management commands do not have to exist yet!

  def test_chgrp_sets_up_chgrp
    assert_recipe_matches %q{
      chgrp "group" "file"
    } do
      chgrp 'group', 'file'
    end
  end

  def test_chgrp_does_nothing_for_nil_group
    assert_recipe %q{
    } do
      chgrp nil, 'file'
    end
  end

  #
  # chmod test
  #

  def test_chomd_chmods_a_file
    setup_recipe do
      cd "${0%/*}"
      touch 'file'
      chmod '644', 'file'
      writeln 'ls -la file'
      chmod '600', 'file'
      writeln 'ls -la file'
    end

    assert_str_match %{
      -rw-r--r-- :...: file
      -rw------- :...: file
    }, *run_package
  end

  def test_chomd_converts_fixnums_to_octal
    assert_recipe %q{
      chmod "644" "file"
    } do
      chmod 0644, 'file'
    end
  end

  def test_chmod_does_nothing_for_no_mode
    assert_recipe %q{
    } do
      chmod nil, 'file'
    end
  end

  #
  # chown test
  #

  # Don't know how to encapsulate test chown at this point... technically user
  # management commands do not have to exist yet!

  def test_chown_sets_up_file_chown
    assert_recipe_matches %q{
      chown "owner:group" "file"
    } do
      chown 'owner:group', 'file'
    end
  end

  def test_chown_does_nothing_for_nil_owner
    assert_recipe %q{
    } do
      chown nil, 'file'
    end
  end

  #
  # cp test
  #

  def test_cp
    assert_recipe %q{
      cp "source" "target"
    } do
      cp 'source', 'target'
    end
  end

  #
  # date test
  #

  def test_date
    assert_recipe %q{
      date
    } do
      date
    end
  end

  #
  # directory? test
  #

  def test_directory_check_checks_dir_exists_and_is_a_directory
    setup_recipe do
      cd "${0%/*}"

      writeln 'mkdir dir'
      writeln 'touch file'
      writeln 'ln -s file link'

      if_ _directory?('dir')  do echo 'dir'  end
      if_ _directory?('file') do echo 'file' end
      if_ _directory?('link') do echo 'link' end
      if_ _directory?('non')  do echo 'fail' end
    end

    assert_str_equal %{
      dir
    }, *run_package
  end

  #
  # echo test
  #

  def test_echo
    assert_recipe(%{
      echo "a b c"
    }){
      echo 'a b c'
    }
  end

  #
  # executable? test
  #

  def test_executable_check_checks_file_is_executable
    setup_recipe do
      cd "${0%/*}"

      writeln 'touch file'
      writeln 'chmod +x file'
      if_ _executable?('file')  do echo 'success'  end

      writeln 'chmod -x file'
      if_ _executable?('file')  do echo 'fail'  end
    end

    assert_str_equal %{
      success
    }, *run_package
  end

  #
  # exists? test
  #

  def test_exists_check_checks_file_exists
    setup_recipe do
      cd "${0%/*}"

      writeln 'mkdir dir'
      writeln 'touch file'
      writeln 'ln -s file link'

      if_ _exists?('dir')  do echo 'dir'  end
      if_ _exists?('file') do echo 'file' end
      if_ _exists?('link') do echo 'link' end
      if_ _exists?('fail') do echo 'fail' end
    end

    assert_str_equal %{
      dir
      file
      link
    }, *run_package
  end

  #
  # export test
  #

  def test_export_exports_variables
    assert_recipe %q{
      export ONE="A"
      export TWO="B C"
    } do
      export 'ONE', 'A'
      export 'TWO', 'B C'
    end
  end

  #
  # file? test
  #

  def test_file_check_checks_file_exists_and_is_a_file
    setup_recipe do
      cd "${0%/*}"

      writeln 'mkdir dir'
      writeln 'touch file'
      writeln 'ln -s file link'

      if_ _file?('dir')  do echo 'dir'  end
      if_ _file?('file') do echo 'file' end
      if_ _file?('link') do echo 'link' end
      if_ _file?('non')  do echo 'fail' end
    end

    assert_str_equal %{
      file
      link
    }, *run_package
  end

  #
  # has_content? test
  #

  def test_has_content_check_checks_file_exists_and_has_content
    setup_recipe do
      cd "${0%/*}"

      writeln 'touch file'
      if_ _has_content?('file')  do echo 'fail'  end

      writeln 'echo content > file'
      if_ _has_content?('file')  do echo 'success'  end
    end

    assert_str_equal %{
      success
    }, *run_package
  end

  #
  # link? test
  #

  def test_link_check_checks_link_exists_and_is_a_link
    setup_recipe do
      cd "${0%/*}"

      writeln 'mkdir dir'
      writeln 'touch file'
      writeln 'ln -s file link'

      if_ _link?('dir')  do echo 'dir'  end
      if_ _link?('file') do echo 'file' end
      if_ _link?('link') do echo 'link' end
      if_ _link?('non')  do echo 'fail' end
    end

    assert_str_equal %{
      link
    }, *run_package
  end

  #
  # ln test
  #

  def test_ln
    assert_recipe %q{
      ln "source" "target"
    } do
      ln 'source', 'target'
    end
  end

  #
  # mkdir test
  #

  def test_mkdir
    assert_recipe %q{
      mkdir "target"
    } do
      mkdir 'target'
    end
  end

  #
  # mv test
  #

  def test_mv
    assert_recipe %q{
      mv "source" "target"
    } do
      mv 'source', 'target'
    end
  end

  #
  # pwd test
  #

  def test_pwd
    assert_recipe %q{
      pwd
    } do
      pwd
    end
  end

  #
  # read test
  #

  def test_read
    assert_recipe %q{
      read "xx" "yy"
    } do
      read 'xx', 'yy'
    end
  end

  #
  # readable? test
  #

  def test_readable_check_checks_file_is_readable
    setup_recipe do
      cd "${0%/*}"

      writeln 'touch file'
      writeln 'chmod +r file'
      if_ _readable?('file')  do echo 'success'  end

      writeln 'chmod -r file'
      if_ _readable?('file')  do echo 'fail'  end
    end

    assert_str_equal %{
      success
    }, *run_package
  end

  #
  # rm test
  #

  def test_rm_removes_a_file
    setup_recipe do
      cd "${0%/*}"

      touch 'file'
      rm 'file'

      unless_ _exists?('file') do echo 'success' end
    end

    assert_str_equal %{
      success
    }, *run_package
  end

  def test_rm
    assert_recipe %q{
      rm "file"
    } do
      rm 'file'
    end
  end

  #
  # set test
  #

  def test_set_sets_options_for_the_duration_of_a_block
    setup_recipe do
      writeln 'set -v'
      writeln 'echo a'
      set(:verbose => false, :xtrace => false) do
        writeln 'echo b'
      end
      writeln 'echo c'
    end

    # the number of set operations echoed is a little unpredicatable
    stdout, msg = run_package
    stdout.gsub!(/^set.*\n/, '')

    assert_str_equal %{
      echo a
      a
      b
      echo c
      c
    }, stdout, msg
  end

  #
  # touch test
  #

  def test_touch_touches_a_file
    setup_recipe do
      cd "${0%/*}"

      if_ _exists?('file') do
        echo 'fail'
      end

      touch 'file'
      if_ _exists?('file') do
        echo 'success'
      end
    end

    assert_str_equal %{
      success
    }, *run_package
  end

  #
  # unset test
  #

  def test_unset_unsets_a_list_of_variables
    assert_recipe %q{
      unset "ONE" "TWO"
    } do
      unset 'ONE', 'TWO'
    end
  end

  #
  # writable? test
  #

  def test_writable_check_checks_file_is_writable
    setup_recipe do
      cd "${0%/*}"

      writeln 'touch file'
      writeln 'chmod +w file'
      if_ _writable?('file') do
        echo 'success'
      end

      writeln 'chmod -w file'
      if_ _writable?('file') do
        echo 'fail'
      end
    end

    assert_str_equal %{
      success
    }, *run_package
  end
end