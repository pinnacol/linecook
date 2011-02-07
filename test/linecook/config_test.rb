require File.expand_path('../../test_helper', __FILE__)
require 'linecook/config'
require 'linecook/test/file_test'

class ConfigTest < Test::Unit::TestCase
  include Linecook::Config
  include Linecook::Test::FileTest
  
  #
  # HOST_REGEXP test
  #
  
  def test_HOST_REGEXP_matches_host_line
    assert 'Host host_name' =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal nil, $2
  end
  
  def test_HOST_REGEXP_matches_host_line_with_vm_name
    assert 'Host host_name # [vm_name]' =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal 'vm_name', $2
  end
  
  def test_HOST_REGEXP_is_indifferent_to_whitespace
    assert "   Host\thost_name   \t   #[vm_name]    " =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal 'vm_name', $2
    
    assert " \t  Host    host_name#\t  [vm_name]" =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal 'vm_name', $2
  end
  
  #
  # hosts test
  #
  
  def test_hosts_loads_host_vm_pairs_from_config_file
    path = prepare('config/ssh') do |io|
      io.puts 'Host a # [one]'
      io.puts 'Host b # [two]'
    end
    
    assert_equal({'a' => 'one', 'b' => 'two'}, hosts(path))
  end
  
  def test_hosts_uses_host_name_as_vm_name_if_no_vm_name_is_specified
    path = prepare('config/ssh') do |io|
      io.puts 'Host a'
      io.puts 'Host b'
    end
    assert_equal({'a' => 'a', 'b' => 'b'}, hosts(path))
  end
  
  def test_hosts_loads_no_hosts_if_no_hosts_are_specified
    path = prepare('config/ssh') {|io| }
    assert_equal({}, hosts(path))
  end
end