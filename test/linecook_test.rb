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
      usage: linecook [options]:...:
      :...:
      options:
          -h, --help    :...: print this help
          -v, --version :...: print version
    }
  end
end
